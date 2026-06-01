<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_number',
        'customer_name',
        'subtotal',
        'discount',
        'total_price',
        'payment_method',
        'status',
        'notes',
        'user_id',
    ];

    /**
     * Get the items purchased in this sale.
     */
    public function items(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    /**
     * Get the user who recorded this sale.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
