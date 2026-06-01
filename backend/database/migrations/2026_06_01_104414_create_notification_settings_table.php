<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('notification_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->onDelete('cascade');
            $table->boolean('stok_alert')->default(true);
            $table->boolean('transaksi_alert')->default(true);
            $table->boolean('laporan_alert')->default(true);
            $table->boolean('sistem_alert')->default(true);
            $table->boolean('promo_alert')->default(true);
            $table->integer('stok_limit')->default(10);
            $table->string('laporan_frekuensi')->default('mingguan'); // harian|mingguan|bulanan
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification_settings');
    }
};
