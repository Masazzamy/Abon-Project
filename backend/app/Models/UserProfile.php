<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'phone',
        'business_name',
        'business_address',
        'photo_path',
        'business_logo',
        'business_type',
        'business_scale',
        'city',
        'province',
        'pirt_number',
        'instagram',
        'whatsapp_business',
        'dark_mode',
        'notifications_enabled',
    ];

    protected $casts = [
        'dark_mode' => 'boolean',
        'notifications_enabled' => 'boolean',
    ];

    /**
     * Get the user that owns the profile.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
