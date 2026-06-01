<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockMovement;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class StockMovementController extends Controller
{
    /**
     * Display a listing of stock movements.
     */
    public function index(Request $request)
    {
        $query = StockMovement::with(['product', 'user']);

        // Filter by type if provided
        if ($request->has('type') && in_array($request->type, ['in', 'out', 'adjustment'])) {
            $query->where('type', $request->type);
        }

        // Filter by product_id
        if ($request->has('product_id')) {
            $query->where('product_id', $request->product_id);
        }

        $movements = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar pergerakan stok berhasil diambil',
            'data' => $movements
        ]);
    }

    /**
     * Store a new stock movement.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|exists:products,id',
            'type' => 'required|in:in,out,adjustment',
            'quantity' => 'required|integer', // Positive for in/out. For adjustment, it can be negative or positive.
            'reason' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $productId = $request->product_id;
        $type = $request->type;
        $quantity = $request->quantity;
        $reason = $request->reason;

        // Validation for quantity depending on type
        if (($type === 'in' || $type === 'out') && $quantity <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Untuk tipe in/out, quantity harus bernilai positif'
            ], 422);
        }

        try {
            return DB::transaction(function () use ($productId, $type, $quantity, $reason) {
                $product = Product::lockForUpdate()->find($productId);
                
                $oldStock = $product->stock;
                $newStock = $oldStock;

                if ($type === 'in') {
                    $newStock = $oldStock + $quantity;
                } elseif ($type === 'out') {
                    if ($oldStock < $quantity) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Stok tidak mencukupi untuk melakukan pengurangan. Stok saat ini: ' . $oldStock
                        ], 400);
                    }
                    $newStock = $oldStock - $quantity;
                } elseif ($type === 'adjustment') {
                    // For general adjustment, the quantity represents the delta relative change (+5 or -3)
                    $newStock = $oldStock + $quantity;
                    if ($newStock < 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Stok setelah penyesuaian tidak boleh kurang dari 0'
                        ], 400);
                    }
                }

                // Update product stock
                $product->stock = $newStock;
                $product->save();

                // Create movement record
                $movement = StockMovement::create([
                    'product_id' => $product->id,
                    'user_id' => auth()->id(),
                    'type' => $type,
                    'quantity' => $quantity,
                    'reason' => $reason ?? ($type === 'adjustment' ? 'Penyesuaian Stok' : ($type === 'in' ? 'Stok Masuk' : 'Stok Keluar')),
                ]);

                // Load relationships for response
                $movement->load(['product', 'user']);

                return response()->json([
                    'success' => true,
                    'message' => 'Pergerakan stok berhasil dicatat',
                    'data' => $movement
                ], 201);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mencatat pergerakan stok: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified stock movement.
     */
    public function destroy(string $id)
    {
        try {
            return DB::transaction(function () use ($id) {
                $movement = StockMovement::find($id);

                if (!$movement) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Pergerakan stok tidak ditemukan'
                    ], 404);
                }

                $product = Product::lockForUpdate()->find($movement->product_id);
                
                // Revert stock change
                $oldStock = $product->stock;
                $newStock = $oldStock;

                if ($movement->type === 'in') {
                    // Reverting an addition means subtracting
                    $newStock = $oldStock - $movement->quantity;
                    if ($newStock < 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Gagal menghapus. Mengurangi stok akan menyebabkan stok produk menjadi minus.'
                        ], 400);
                    }
                } elseif ($movement->type === 'out') {
                    // Reverting a subtraction means adding
                    $newStock = $oldStock + $movement->quantity;
                } elseif ($movement->type === 'adjustment') {
                    // Reverting adjustment means subtracting the adjustment quantity
                    $newStock = $oldStock - $movement->quantity;
                    if ($newStock < 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Gagal menghapus. Mengurangi stok penyesuaian akan menyebabkan stok produk menjadi minus.'
                        ], 400);
                    }
                }

                $product->stock = $newStock;
                $product->save();

                $movement->delete();

                return response()->json([
                    'success' => true,
                    'message' => 'Pergerakan stok berhasil dihapus'
                ]);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menghapus pergerakan stok: ' . $e->getMessage()
            ], 500);
        }
    }
}
