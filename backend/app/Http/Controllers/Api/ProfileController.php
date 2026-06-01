<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ProfileController extends Controller
{
    /**
     * Show the user's profile and settings.
     */
    public function show(Request $request)
    {
        $user = $request->user();
        
        // Ensure user has a profile record, initialize if not exists
        $profile = $user->profile()->firstOrCreate([
            'user_id' => $user->id
        ], [
            'business_name' => 'Abon Salakopi',
            'dark_mode' => false,
            'notifications_enabled' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile retrieved successfully',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'profile' => [
                    'phone' => $profile->phone,
                    'business_name' => $profile->business_name,
                    'business_address' => $profile->business_address,
                    'photo_url' => $profile->photo_path ? asset('storage/' . $profile->photo_path) : null,
                    'dark_mode' => $profile->dark_mode,
                    'notifications_enabled' => $profile->notifications_enabled,
                ]
            ]
        ], 200);
    }

    /**
     * Update the user's profile and settings.
     */
    public function update(Request $request)
    {
        $user = $request->user();
        $profile = $user->profile()->firstOrCreate(['user_id' => $user->id]);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
            'phone' => 'nullable|string|max:20',
            'business_name' => 'nullable|string|max:255',
            'business_address' => 'nullable|string',
            'dark_mode' => 'nullable|boolean',
            'notifications_enabled' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        // Update User info
        $user->update([
            'name' => $request->name,
            'email' => $request->email,
        ]);

        // Update Profile settings
        $profile->update([
            'phone' => $request->phone,
            'business_name' => $request->business_name ?? 'Abon Salakopi',
            'business_address' => $request->business_address,
            'dark_mode' => $request->has('dark_mode') ? filter_var($request->dark_mode, FILTER_VALIDATE_BOOLEAN) : $profile->dark_mode,
            'notifications_enabled' => $request->has('notifications_enabled') ? filter_var($request->notifications_enabled, FILTER_VALIDATE_BOOLEAN) : $profile->notifications_enabled,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'profile' => [
                    'phone' => $profile->phone,
                    'business_name' => $profile->business_name,
                    'business_address' => $profile->business_address,
                    'photo_url' => $profile->photo_path ? asset('storage/' . $profile->photo_path) : null,
                    'dark_mode' => $profile->dark_mode,
                    'notifications_enabled' => $profile->notifications_enabled,
                ]
            ]
        ], 200);
    }

    /**
     * Update user's password.
     */
    public function updatePassword(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password saat ini salah',
                'errors' => [
                    'current_password' => ['Password saat ini tidak sesuai']
                ]
            ], 422);
        }

        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah'
        ], 200);
    }

    /**
     * Upload profile picture.
     */
    public function uploadPhoto(Request $request)
    {
        $user = $request->user();
        $profile = $user->profile()->firstOrCreate(['user_id' => $user->id]);

        $validator = Validator::make($request->all(), [
            'photo' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        if ($request->hasFile('photo')) {
            // Delete old photo if it exists
            if ($profile->photo_path && Storage::disk('public')->exists($profile->photo_path)) {
                Storage::disk('public')->delete($profile->photo_path);
            }

            // Save new photo
            $path = $request->file('photo')->store('profiles', 'public');
            $profile->update([
                'photo_path' => $path
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Foto profil berhasil diunggah',
                'photo_url' => asset('storage/' . $path)
            ], 200);
        }

        return response()->json([
            'success' => false,
            'message' => 'Berkas tidak ditemukan'
        ], 400);
    }
}
