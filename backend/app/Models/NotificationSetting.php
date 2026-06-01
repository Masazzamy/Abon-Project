<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'stok_alert',
        'transaksi_alert',
        'laporan_alert',
        'sistem_alert',
        'promo_alert',
        'stok_limit',
        'laporan_frekuensi',
    ];

    protected $casts = [
        'stok_alert' => 'boolean',
        'transaksi_alert' => 'boolean',
        'laporan_alert' => 'boolean',
        'sistem_alert' => 'boolean',
        'promo_alert' => 'boolean',
        'stok_limit' => 'integer',
    ];

    /**
     * Get the user that owns the settings.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
