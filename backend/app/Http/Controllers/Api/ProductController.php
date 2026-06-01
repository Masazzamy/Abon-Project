<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class ProductController extends Controller
{
    /**
     * Display a listing of products.
     */
    public function index(Request $request)
    {
        $query = Product::query();

        // Filter products with low stock (stock <= min_stock)
        if ($request->has('low_stock') && $request->boolean('low_stock')) {
            $query->whereRaw('stock <= min_stock');
        }

        $products = $query->orderBy('name', 'asc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar produk berhasil diambil',
            'data' => $products
        ]);
    }

    /**
     * Store a newly created product.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'sku' => 'required|string|max:100|unique:products,sku',
            'description' => 'nullable|string',
            'price' => 'required|integer|min:0',
            'stock' => 'nullable|integer|min:0',
            'min_stock' => 'nullable|integer|min:0',
            'unit' => 'required|string|max:50',
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
                $initialStock = $request->input('stock', 0);

                $product = Product::create([
                    'name' => $request->name,
                    'sku' => $request->sku,
                    'description' => $request->description,
                    'price' => $request->price,
                    'stock' => $initialStock,
                    'min_stock' => $request->input('min_stock', 5),
                    'unit' => $request->unit,
                ]);

                // Record initial stock movement if it is greater than 0
                if ($initialStock > 0) {
                    StockMovement::create([
                        'product_id' => $product->id,
                        'user_id' => auth()->id(),
                        'type' => 'in',
                        'quantity' => $initialStock,
                        'reason' => 'Stok Awal',
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Produk berhasil ditambahkan',
                    'data' => $product
                ], 201);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menambahkan produk: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified product.
     */
    public function show(string $id)
    {
        $product = Product::with(['stockMovements' => function ($q) {
            $q->orderBy('created_at', 'desc');
        }])->find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail produk berhasil diambil',
            'data' => $product
        ]);
    }

    /**
     * Update the specified product.
     */
    public function update(Request $request, string $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'sku' => 'sometimes|required|string|max:100|unique:products,sku,' . $id,
            'description' => 'nullable|string',
            'price' => 'sometimes|required|integer|min:0',
            'min_stock' => 'sometimes|required|integer|min:0',
            'unit' => 'sometimes|required|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $product->update($request->only(['name', 'sku', 'description', 'price', 'min_stock', 'unit']));

        return response()->json([
            'success' => true,
            'message' => 'Produk berhasil diperbarui',
            'data' => $product
        ]);
    }

    /**
     * Remove the specified product.
     */
    public function destroy(string $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan'
            ], 404);
        }

        $product->delete();

        return response()->json([
            'success' => true,
            'message' => 'Produk berhasil dihapus'
        ]);
    }

    /**
     * Adjust product stock (record in/out/adjustment movement).
     */
    public function adjustStock(Request $request, string $id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Produk tidak ditemukan'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'type' => 'required|in:in,out,adjustment',
            'quantity' => 'required|integer', // Can be negative for adjustment only
            'reason' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $type = $request->type;
        $quantity = $request->quantity;

        // Validations for positive movements
        if (($type === 'in' || $type === 'out') && $quantity <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Untuk tipe in/out, quantity harus bernilai positif'
            ], 422);
        }

        try {
            return DB::transaction(function () use ($product, $type, $quantity, $request) {
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
                    // For adjustment, quantity represents the new absolute stock level,
                    // and we record the difference as the movement quantity.
                    $newStock = $quantity;
                    if ($newStock < 0) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Stok setelah penyesuaian tidak boleh kurang dari 0'
                        ], 422);
                    }
                    $quantity = $newStock - $oldStock; // This delta will be recorded
                }

                // Update product stock
                $product->stock = $newStock;
                $product->save();

                // Record movement (only if there is an actual change)
                if ($quantity != 0) {
                    StockMovement::create([
                        'product_id' => $product->id,
                        'user_id' => auth()->id(),
                        'type' => $type,
                        'quantity' => $quantity,
                        'reason' => $request->input('reason', $type === 'adjustment' ? 'Penyesuaian Stok' : ($type === 'in' ? 'Stok Masuk' : 'Stok Keluar')),
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Stok berhasil disesuaikan',
                    'data' => [
                        'product_id' => $product->id,
                        'name' => $product->name,
                        'old_stock' => $oldStock,
                        'new_stock' => $newStock,
                    ]
                ]);
            });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal menyesuaikan stok: ' . $e->getMessage()
            ], 500);
        }
    }
}
