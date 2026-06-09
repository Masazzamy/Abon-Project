<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // ===========================
        // Akun Test — CEO (Pemilik)
        // ===========================
        $ceo = User::create([
            'name'     => 'Budi Santoso',
            'email'    => 'ceo@abon.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role'     => 'ceo',
        ]);
        $ceo->profile()->create([
            'phone'                  => '081111111111',
            'business_name'          => 'Abon Salakopi',
            'business_address'       => 'Jl. Salakopi No. 12, Tasikmalaya',
            'dark_mode'              => false,
            'notifications_enabled'  => true,
        ]);

        // ===========================
        // Akun Test — Admin
        // ===========================
        $admin = User::create([
            'name'     => 'Admin Utama',
            'email'    => 'admin@abon.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role'     => 'admin',
        ]);
        $admin->profile()->create([
            'phone'                  => '082222222222',
            'business_name'          => 'Abon Salakopi',
            'dark_mode'              => false,
            'notifications_enabled'  => true,
        ]);

        // ===========================
        // Akun Test — Kasir
        // ===========================
        $kasir = User::create([
            'name'     => 'Siti Kasir',
            'email'    => 'kasir@abon.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role'     => 'cashier',
        ]);
        $kasir->profile()->create([
            'phone'                  => '083333333333',
            'dark_mode'              => false,
            'notifications_enabled'  => true,
        ]);

        // ===========================
        // Akun Test — Gudang
        // ===========================
        $gudang = User::create([
            'name'     => 'Rudi Gudang',
            'email'    => 'gudang@abon.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role'     => 'warehouse',
        ]);
        $gudang->profile()->create([
            'phone'                  => '084444444444',
            'dark_mode'              => false,
            'notifications_enabled'  => true,
        ]);
    }
}
