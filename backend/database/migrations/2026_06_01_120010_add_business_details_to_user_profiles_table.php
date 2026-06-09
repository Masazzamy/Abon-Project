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
        Schema::table('user_profiles', function (Blueprint $table) {
            $table->string('business_logo')->nullable()->after('photo_path');
            $table->string('business_type')->nullable()->after('business_name');
            $table->string('business_scale')->nullable()->after('business_type');
            $table->string('city')->nullable()->after('business_address');
            $table->string('province')->nullable()->after('city');
            $table->string('pirt_number')->nullable()->after('province');
            $table->string('instagram')->nullable()->after('pirt_number');
            $table->string('whatsapp_business')->nullable()->after('instagram');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('user_profiles', function (Blueprint $table) {
            $table->dropColumn([
                'business_logo',
                'business_type',
                'business_scale',
                'city',
                'province',
                'pirt_number',
                'instagram',
                'whatsapp_business',
            ]);
        });
    }
};
