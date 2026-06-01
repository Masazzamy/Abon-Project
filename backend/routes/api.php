<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SaleController;
use App\Http\Controllers\Api\StockMovementController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\NotificationController;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/ping', function () {
    return response()->json([
        'success' => true,
        'message' => 'Koneksi ke backend Laravel BERHASIL!',
        'time' => now()->toIso8601String(),
    ]);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'getUser']);

    // Profile routes
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/password', [ProfileController::class, 'updatePassword']);
    Route::post('/profile/photo', [ProfileController::class, 'uploadPhoto']);

    // Inventory/Products routes
    Route::apiResource('/products', ProductController::class);
    Route::post('/products/{id}/adjust-stock', [ProductController::class, 'adjustStock']);

    // Sales routes
    Route::apiResource('/sales', SaleController::class)->except(['update', 'destroy']);
    Route::post('/sales/{id}/cancel', [SaleController::class, 'cancel']);

    // Stock Movement routes
    Route::apiResource('/stock-movements', StockMovementController::class)->except(['update']);

    // Reports routes
    Route::get('/reports/summary', [ReportController::class, 'getSummary']);

    // Notification routes
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/read-all', [NotificationController::class, 'readAll']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'read']);
    Route::post('/notifications/{id}/unread', [NotificationController::class, 'unread']);
    Route::delete('/notifications/clear-all', [NotificationController::class, 'clearAll']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    Route::get('/notifications/settings', [NotificationController::class, 'getSettings']);
    Route::put('/notifications/settings', [NotificationController::class, 'updateSettings']);
});
