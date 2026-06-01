<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Product;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ReportController extends Controller
{
    /**
     * Get comprehensive business report analytics.
     */
    public function getSummary(Request $request)
    {
        // 1. Parse Period Filter
        $period = $request->input('period', 'month'); // day, week, month, custom
        $startDate = null;
        $endDate = null;

        if ($period === 'day') {
            $startDate = Carbon::today()->startOfDay();
            $endDate = Carbon::today()->endOfDay();
        } elseif ($period === 'week') {
            $startDate = Carbon::now()->startOfWeek();
            $endDate = Carbon::now()->endOfWeek();
        } elseif ($period === 'month') {
            $startDate = Carbon::now()->startOfMonth();
            $endDate = Carbon::now()->endOfMonth();
        } elseif ($period === 'custom') {
            $startDate = $request->has('start_date') ? Carbon::parse($request->start_date)->startOfDay() : Carbon::now()->startOfMonth();
            $endDate = $request->has('end_date') ? Carbon::parse($request->end_date)->endOfDay() : Carbon::now()->endOfMonth();
        } else {
            $startDate = Carbon::now()->startOfMonth();
            $endDate = Carbon::now()->endOfMonth();
        }

        // --- KEUANGAN & PENJUALAN ---
        $salesQuery = Sale::whereBetween('created_at', [$startDate, $endDate]);
        
        $totalRevenue = (int) $salesQuery->sum('total_amount');
        $totalTransactions = $salesQuery->count();
        
        // Modal / Cost of production is estimated at 60% of selling price
        $totalCost = (int) ($totalRevenue * 0.6);
        $netProfit = $totalRevenue - $totalCost;
        
        // Active days in period
        $activeDays = $startDate->diffInDays($endDate) + 1;
        $dailyAverage = $activeDays > 0 ? (int) ($totalRevenue / $activeDays) : $totalRevenue;

        // Daily revenue vs cost series
        $daysSeries = [];
        $tempDate = $startDate->copy();
        while ($tempDate->lte($endDate)) {
            $daySales = Sale::whereDate('created_at', $tempDate)->sum('total_amount');
            $daysSeries[] = [
                'date' => $tempDate->format('Y-m-d'),
                'label' => $tempDate->format('d/m'),
                'revenue' => (int) $daySales,
                'cost' => (int) ($daySales * 0.6),
                'profit' => (int) ($daySales * 0.4),
            ];
            $tempDate->addDay();
        }

        // Product Contributions (Pie chart slices)
        $contributions = SaleItem::select('product_id', DB::raw('SUM(quantity) as total_qty'), DB::raw('SUM(price * quantity) as total_revenue'))
            ->whereHas('sale', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate]);
            })
            ->groupBy('product_id')
            ->with('product')
            ->get();

        $productContributions = [];
        $totalContribRevenue = $contributions->sum('total_revenue');
        foreach ($contributions as $item) {
            if ($item->product) {
                $percentage = $totalContribRevenue > 0 ? round(($item->total_revenue / $totalContribRevenue) * 100, 1) : 0;
                $productContributions[] = [
                    'product_id' => $item->product_id,
                    'name' => $item->product->name,
                    'quantity' => (int) $item->total_qty,
                    'revenue' => (int) $item->total_revenue,
                    'percentage' => $percentage,
                ];
            }
        }

        // Distinct products sold count
        $distinctProductsCount = SaleItem::whereHas('sale', function ($q) use ($startDate, $endDate) {
            $q->whereBetween('created_at', [$startDate, $endDate]);
        })->distinct('product_id')->count('product_id');

        // Total items sold
        $totalItemsSold = (int) SaleItem::whereHas('sale', function ($q) use ($startDate, $endDate) {
            $q->whereBetween('created_at', [$startDate, $endDate]);
        })->sum('quantity');

        // Top 5 Products List
        $topProductsQuery = SaleItem::select('product_id', DB::raw('SUM(quantity) as total_qty'), DB::raw('SUM(price * quantity) as total_revenue'))
            ->whereHas('sale', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate]);
            })
            ->groupBy('product_id')
            ->orderBy('total_qty', 'desc')
            ->limit(5)
            ->with('product')
            ->get();

        $topProducts = [];
        $rank = 1;
        foreach ($topProductsQuery as $top) {
            if ($top->product) {
                $topProducts[] = [
                    'rank' => $rank++,
                    'product_id' => $top->product_id,
                    'name' => $top->product->name,
                    'sold_count' => (int) $top->total_qty,
                    'revenue' => (int) $top->total_revenue,
                ];
            }
        }

        // Hourly Sales (00 - 23)
        $hourlySales = array_fill(0, 24, 0);
        $hourlyData = Sale::whereBetween('created_at', [$startDate, $endDate])
            ->select(DB::raw('HOUR(created_at) as hour'), DB::raw('COUNT(*) as count'))
            ->groupBy('hour')
            ->get();
        foreach ($hourlyData as $hd) {
            $hourlySales[(int) $hd->hour] = (int) $hd->count;
        }

        // Payment Methods
        $paymentMethods = [
            'Tunai' => 0,
            'Transfer' => 0,
            'QRIS' => 0,
        ];
        $paymentData = Sale::whereBetween('created_at', [$startDate, $endDate])
            ->select('payment_method', DB::raw('COUNT(*) as count'))
            ->groupBy('payment_method')
            ->get();
        foreach ($paymentData as $pd) {
            $pm = $pd->payment_method;
            if ($pm === 'cash' || strtolower($pm) === 'tunai') {
                $paymentMethods['Tunai'] += (int) $pd->count;
            } elseif ($pm === 'transfer') {
                $paymentMethods['Transfer'] += (int) $pd->count;
            } elseif ($pm === 'qris') {
                $paymentMethods['QRIS'] += (int) $pd->count;
            }
        }

        // --- STOK (INVENTARIS) ---
        $allProducts = Product::all();
        $totalStockValue = 0;
        $activeProductsCount = 0;
        $outOfStockCount = 0;
        
        $stockStatus = [
            'aman' => 0, // > 10
            'menipis' => 0, // 1-10
            'habis' => 0, // 0
        ];

        $productStockTable = [];
        foreach ($allProducts as $p) {
            $stock = $p->stock;
            $val = (int) ($stock * ($p->price * 0.6)); // stock value at cost price
            $totalStockValue += $val;

            if ($stock > 10) {
                $status = 'aman';
                $stockStatus['aman']++;
            } elseif ($stock > 0) {
                $status = 'menipis';
                $stockStatus['menipis']++;
            } else {
                $status = 'habis';
                $stockStatus['habis']++;
            }

            if ($stock > 0) {
                $activeProductsCount++;
            } else {
                $outOfStockCount++;
            }

            $productStockTable[] = [
                'name' => $p->name,
                'stock' => $stock,
                'unit' => $p->unit,
                'value' => $val,
                'status' => $status,
            ];
        }

        // 7-day stock movements (inbound/outbound)
        $stockMovements7Days = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::today()->subtractDays($i);
            $inQty = (int) StockMovement::whereDate('created_at', $date)->where('type', 'in')->sum('quantity');
            $outQty = (int) StockMovement::whereDate('created_at', $date)->where('type', 'out')->sum('quantity');

            $stockMovements7Days[] = [
                'date' => $date->format('Y-m-d'),
                'label' => $date->format('d/m'),
                'in' => $inQty,
                'out' => abs($outQty),
            ];
        }

        // --- HARIAN (CALENDAR HEATMAP & DETAIL) ---
        // Calendar heatmap (current month mapping)
        $calendarHeatmap = [];
        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $tempHeat = $monthStart->copy();
        while ($tempHeat->lte($monthEnd)) {
            $dayCount = Sale::whereDate('created_at', $tempHeat)->count();
            $calendarHeatmap[$tempHeat->format('Y-m-d')] = $dayCount;
            $tempHeat->addDay();
        }

        return response()->json([
            'success' => true,
            'message' => 'Laporan bisnis berhasil diolah',
            'data' => [
                'keuangan' => [
                    'total_revenue' => $totalRevenue,
                    'total_cost' => $totalCost,
                    'net_profit' => $netProfit,
                    'margin_percentage' => $totalRevenue > 0 ? (int) (($netProfit / $totalRevenue) * 100) : 0,
                    'total_transactions' => $totalTransactions,
                    'daily_average' => $dailyAverage,
                    'days_series' => $daysSeries,
                    'product_contributions' => $productContributions,
                ],
                'penjualan' => [
                    'total_items_sold' => $totalItemsSold,
                    'distinct_products_count' => $distinctProductsCount,
                    'top_products' => $topProducts,
                    'hourly_sales' => $hourlySales,
                    'payment_methods' => $paymentMethods,
                ],
                'stok' => [
                    'total_stock_value' => $totalStockValue,
                    'active_products_count' => $activeProductsCount,
                    'out_of_stock_count' => $outOfStockCount,
                    'stock_status' => $stockStatus,
                    'stock_movements_7_days' => $stockMovements7Days,
                    'product_stock_table' => $productStockTable,
                ],
                'harian' => [
                    'calendar_heatmap' => $calendarHeatmap,
                    'daily_comparison' => array_slice($daysSeries, -7), // last 7 days of active period
                ]
            ]
        ]);
    }
}
