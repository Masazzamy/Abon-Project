<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'tipe',
        'judul',
        'pesan',
        'sudah_dibaca',
        'is_urgent',
        'data',
    ];

    protected $casts = [
        'sudah_dibaca' => 'boolean',
        'is_urgent' => 'boolean',
        'data' => 'array',
    ];

    /**
     * Get the user that owns the notification.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
