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
        // User::factory(10)->create();

        $user = User::create([
            'name' => 'Admin',
            'email' => 'admin@abon.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password'),
            'role' => 'admin',
        ]);

        $user->profile()->create([
            'phone' => '081234567890',
            'business_name' => 'Abon Salakopi',
            'business_address' => 'Jl. Salakopi No. 12, Tasikmalaya, Jawa Barat',
            'dark_mode' => false,
            'notifications_enabled' => true,
        ]);
    }
}
