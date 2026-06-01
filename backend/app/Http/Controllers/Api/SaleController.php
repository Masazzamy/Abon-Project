<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SaleController extends Controller
{
    /**
     * Display a listing of transactions.
     */
    public function index(Request $request)
    {
        $query = Sale::with(['items.product', 'user']);

        // Filter by search query (customer name or invoice number)
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('customer_name', 'like', '%' . $search . '%')
                  ->orWhere('invoice_number', 'like', '%' . $search . '%');
            });
        }

        // Filter by status
        if ($request->has('status') && $request->status != '' && $request->status != 'Semua') {
            $query->where('status', strtolower($request->status));
        }

        // Filter by period
        if ($request->has('period') && $request->period != '' && $request->period != 'Semua') {
            $period = $request->period;
            $now = Carbon::now();

            if ($period === 'Hari Ini') {
                $query->whereDate('created_at', Carbon::today());
            } elseif ($period === 'Minggu Ini') {
                $query->whereBetween('created_at', [$now->startOfWeek()->format('Y-m-d H:i:s'), $now->endOfWeek()->format('Y-m-d H:i:s')]);
            } elseif ($period === 'Bulan Ini') {
                $query->whereMonth('created_at', Carbon::now()->month)
                      ->whereYear('created_at', Carbon::now()->year);
            }
        }

        $sales = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar transaksi berhasil diambil',
            'data' => $sales
        ]);
    }

    /**
     * Store a newly created transaction.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_name' => 'nullable|string|max:255',
            'discount' => 'nullable|integer|min:0',
            'payment_method' => 'required|in:cash,transfer,qris',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            return DB::transaction(function () use ($request) {
                // Generate Invoice Number: TRX-YYYYMMDD-XXXX (seconds + random)
                $invoiceNumber = 'TRX-' . Carbon::now()->format('Ymd') . '-' . strtoupper(substr(uniqid(), -4));

                $subtotal = 0;
                $itemsToCreate = [];

                // Validate stock levels and calculate subtotal
                foreach ($request->items as $item) {
                    $product = Product::find($item['product_id']);
                    $qty = $item['quantity'];

                    if ($product->stock < $qty) {
                        throw new \Exception("Stok produk '{$product->name}' tidak mencukupi. Sisa stok: {$product->stock}.");
                    }

                    $itemSubtotal = $product->price * $qty;
                    $subtotal += $itemSubtotal;

                    $itemsToCreate[] = [
                        'product_id' => $product->id,
                        'quantity' => $qty,
                        'price' => $product->price, // Store historical price
                        'product_model' => $product
                    ];
                }

                $discount = $request->input('discount', 0);
                $totalPrice = $subtotal - $discount;
                if ($totalPrice < 0) {
                    $totalPrice = 0;
                }

                // Create Sale Header
                $sale = Sale::create([
                    'invoice_number' => $invoiceNumber,
                    'customer_name' => $request->customer_name,
                    'subtotal' => $subtotal,
                    'discount' => $discount,
                    'total_price' => $totalPrice,
                    'payment_method' => $request->payment_method,
                    'status' => 'success',
                    'notes' => $request->notes,
                    'user_id' => auth()->id(),
                ]);

                // Create Sale Items and update inventory
                foreach ($itemsToCreate as $itemData) {
                    SaleItem::create([
                        'sale_id' => $sale->id,
                        'product_id' => $itemData['product_id'],
                        'quantity' => $itemData['quantity'],
                        'price' => $itemData['price'],
                    ]);

                    // Update product stock count
                    $product = $itemData['product_model'];
                    $product->stock = $product->stock - $itemData['quantity'];
                    $product->save();

                    // Log Stock Movement
                    StockMovement::create([
                        'product_id' => $product->id,
                        'user_id' => auth()->id(),
                        'type' => 'out',
                        'quantity' => $itemData['quantity'],
                        'reason' => "Penjualan #{$invoiceNumber}",
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Transaksi berhasil dicatat',
                    'data' => Sale::with('items.product')->find($sale->id)
                ], 201);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Display details of a specific transaction.
     */
    public function show(string $id)
    {
        $sale = Sale::with(['items.product', 'user'])->find($id);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Transaksi tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail transaksi berhasil diambil',
            'data' => $sale
        ]);
    }

    /**
     * Cancel a transaction.
     */
    public function cancel(string $id)
    {
        $sale = Sale::with('items')->find($id);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Transaksi tidak ditemukan'
            ], 404);
        }

        if ($sale->status === 'cancelled') {
            return response()->json([
                'success' => false,
                'message' => 'Transaksi ini sudah dibatalkan sebelumnya'
            ], 400);
        }

        try {
            return DB::transaction(function () use ($sale) {
                // Update Sale Status
                $sale->status = 'cancelled';
                $sale->save();

                // Restore stock levels and log stock movements
                foreach ($sale->items as $item) {
                    $product = Product::find($item->product_id);
                    if ($product) {
                        $product->stock = $product->stock + $item->quantity;
                        $product->save();

                        // Log Stock Movement (incoming back)
                        StockMovement::create([
                            'product_id' => $product->id,
                            'user_id' => auth()->id(),
                            'type' => 'in',
                            'quantity' => $item->quantity,
                            'reason' => "Pembatalan Penjualan #{$sale->invoice_number}",
                        ]);
                    }
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Transaksi berhasil dibatalkan dan stok dikembalikan',
                    'data' => Sale::with('items.product')->find($sale->id)
                ]);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal membatalkan transaksi: ' . $e->getMessage()
            ], 500);
        }
    }
}
