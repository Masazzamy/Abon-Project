<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\NotificationSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user, filtered by type if provided.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        // Auto-seed dummy notifications if database is empty for this user
        if ($user->notifications()->count() == 0) {
            $this->seedDummyNotifications($user->id);
        }

        $query = $user->notifications();

        // Optional filter by tipe
        if ($request->has('tipe') && $request->tipe !== 'semua') {
            $query->where('tipe', $request->tipe);
        }

        $notifications = $query->orderBy('created_at', 'desc')->get();

        // Calculate unread counts
        $allUnread = $user->notifications()->where('sudah_dibaca', false)->get();
        $unreadCounts = [
            'semua' => $allUnread->count(),
            'stok' => $allUnread->where('tipe', 'stok')->count(),
            'transaksi' => $allUnread->where('tipe', 'transaksi')->count(),
            'laporan' => $allUnread->where('tipe', 'laporan')->count(),
            'sistem' => $allUnread->where('tipe', 'sistem')->count(),
            'promo' => $allUnread->where('tipe', 'promo')->count(),
        ];

        return response()->json([
            'success' => true,
            'message' => 'Notifications retrieved successfully',
            'data' => [
                'notifications' => $notifications,
                'unread_counts' => $unreadCounts
            ]
        ], 200);
    }

    /**
     * Mark a notification as read.
     */
    public function read($id, Request $request)
    {
        $user = $request->user();
        $notification = $user->notifications()->find($id);

        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found'
            ], 404);
        }

        $notification->update(['sudah_dibaca' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read',
            'data' => $notification
        ], 200);
    }

    /**
     * Mark a notification as unread.
     */
    public function unread($id, Request $request)
    {
        $user = $request->user();
        $notification = $user->notifications()->find($id);

        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found'
            ], 404);
        }

        $notification->update(['sudah_dibaca' => false]);

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as unread',
            'data' => $notification
        ], 200);
    }

    /**
     * Mark all notifications as read.
     */
    public function readAll(Request $request)
    {
        $user = $request->user();
        $user->notifications()->where('sudah_dibaca', false)->update(['sudah_dibaca' => true]);

        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read'
        ], 200);
    }

    /**
     * Delete a single notification.
     */
    public function destroy($id, Request $request)
    {
        $user = $request->user();
        $notification = $user->notifications()->find($id);

        if (!$notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notification not found'
            ], 404);
        }

        // Urgent stock alerts shouldn't be deleted if stock is still critical (mock logic, or bypass if is_urgent)
        if ($notification->is_urgent && $notification->tipe == 'stok') {
            // In a real app we'd check actual product stock, here we check a mock flag in the 'data' column
            $productData = $notification->data;
            if (isset($productData['stock']) && $productData['stock'] == 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Notifikasi stok habis (URGENT) tidak dapat dihapus sebelum stok di-restock!'
                ], 400);
            }
        }

        $notification->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notification deleted successfully'
        ], 200);
    }

    /**
     * Clear all notifications for the user.
     */
    public function clearAll(Request $request)
    {
        $user = $request->user();
        
        // Delete all notifications except urgent stock alerts that are still critical
        $deletedCount = 0;
        $notifications = $user->notifications()->get();
        
        foreach ($notifications as $notification) {
            if ($notification->is_urgent && $notification->tipe == 'stok') {
                $productData = $notification->data;
                if (isset($productData['stock']) && $productData['stock'] == 0) {
                    continue; // Skip deleting urgent empty stock
                }
            }
            $notification->delete();
            $deletedCount++;
        }

        return response()->json([
            'success' => true,
            'message' => "Successfully cleared $deletedCount notifications. Urgent notifications retained if any."
        ], 200);
    }

    /**
     * Get user's notification settings.
     */
    public function getSettings(Request $request)
    {
        $user = $request->user();
        $settings = $user->notificationSetting()->firstOrCreate([
            'user_id' => $user->id
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Settings retrieved successfully',
            'data' => $settings
        ], 200);
    }

    /**
     * Update user's notification settings.
     */
    public function updateSettings(Request $request)
    {
        $user = $request->user();
        $settings = $user->notificationSetting()->firstOrCreate([
            'user_id' => $user->id
        ]);

        $validator = Validator::make($request->all(), [
            'stok_alert' => 'nullable|boolean',
            'transaksi_alert' => 'nullable|boolean',
            'laporan_alert' => 'nullable|boolean',
            'sistem_alert' => 'nullable|boolean',
            'promo_alert' => 'nullable|boolean',
            'stok_limit' => 'nullable|integer|min:1|max:100',
            'laporan_frekuensi' => 'nullable|string|in:harian,mingguan,bulanan',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $settings->update($request->only([
            'stok_alert',
            'transaksi_alert',
            'laporan_alert',
            'sistem_alert',
            'promo_alert',
            'stok_limit',
            'laporan_frekuensi'
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Settings updated successfully',
            'data' => $settings
        ], 200);
    }

    /**
     * Seeder for dummy notifications for a user.
     */
    private function seedDummyNotifications($userId)
    {
        $now = Carbon::now();

        $dummies = [
            [
                'user_id' => $userId,
                'tipe' => 'transaksi',
                'judul' => '✅ Transaksi Berhasil!',
                'pesan' => 'Penjualan Abon Salakopi Pedas x5 senilai Rp 125.000 berhasil dicatat.',
                'sudah_dibaca' => false,
                'is_urgent' => false,
                'data' => [
                    'transaction_id' => 'TRX-20260523-001',
                    'product_name' => 'Abon Salakopi Pedas',
                    'qty' => 5,
                    'amount' => 125000,
                    'payment_method' => 'Tunai'
                ],
                'created_at' => $now->copy()->subMinutes(5),
            ],
            [
                'user_id' => $userId,
                'tipe' => 'stok',
                'judul' => '⚠️ Stok Menipis!',
                'pesan' => 'Produk Abon Salakopi Original tersisa 8 pcs. Segera lakukan restock sebelum kehabisan.',
                'sudah_dibaca' => false,
                'is_urgent' => false,
                'data' => [
                    'product_id' => 1,
                    'product_name' => 'Abon Salakopi Original',
                    'stock' => 8,
                    'min_stock' => 10
                ],
                'created_at' => $now->copy()->subHours(2),
            ],
            [
                'user_id' => $userId,
                'tipe' => 'stok',
                'judul' => '🚨 URGENT: STOK HABIS!',
                'pesan' => 'Stok untuk produk Abon Salakopi Manis telah 0 (HABIS)! Harap segera lakukan restock untuk melanjutkan penjualan.',
                'sudah_dibaca' => false,
                'is_urgent' => true,
                'data' => [
                    'product_id' => 2,
                    'product_name' => 'Abon Salakopi Manis',
                    'stock' => 0,
                    'min_stock' => 10
                ],
                'created_at' => $now->copy()->subHours(4),
            ],
            [
                'user_id' => $userId,
                'tipe' => 'laporan',
                'judul' => '📊 Laporan Harian Siap',
                'pesan' => 'Laporan penjualan hari Sabtu, 23 Mei 2026 sudah tersedia. Total pendapatan: Rp 875.000.',
                'sudah_dibaca' => false,
                'is_urgent' => false,
                'data' => [
                    'period' => 'Harian',
                    'date' => '2026-05-23',
                    'revenue' => 875000,
                    'transactions_count' => 12
                ],
                'created_at' => $now->copy()->subDays(1)->setHour(20)->setMinute(0),
            ],
            [
                'user_id' => $userId,
                'tipe' => 'promo',
                'judul' => '🎯 Pengingat Stok Opname',
                'pesan' => 'Sudah 30 hari sejak stock opname terakhir. Yuk lakukan pengecekan stok fisik Anda sekarang!',
                'sudah_dibaca' => true,
                'is_urgent' => false,
                'data' => null,
                'created_at' => $now->copy()->subDays(3),
            ],
            [
                'user_id' => $userId,
                'tipe' => 'sistem',
                'judul' => 'ℹ️ Selamat Datang!',
                'pesan' => 'Akun Anda berhasil dibuat. Mulai kelola usaha abon Anda dengan lebih mudah bersama Abon Salakopi App.',
                'sudah_dibaca' => true,
                'is_urgent' => false,
                'data' => null,
                'created_at' => $now->copy()->subDays(7),
            ]
        ];

        foreach ($dummies as $dummy) {
            Notification::create($dummy);
        }
    }
}
