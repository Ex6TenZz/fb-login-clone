// src/components/ModernLogin.tsx

import Image from "next/image";

export default function ModernLogin() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-sky-100 to-indigo-200 flex items-center justify-center">
      <div className="bg-white shadow-2xl rounded-2xl flex max-w-5xl w-full overflow-hidden">
        
        {/* Left panel */}
        <div className="w-1/2 bg-indigo-700 text-white p-10 flex flex-col justify-center">
          <Image src="/logo-modern.svg" alt="Logo" width={160} height={40} />
          <h2 className="text-3xl font-bold mt-10">Connect Differently.</h2>
          <p className="mt-4 text-indigo-100">Your social experience, redesigned. Clean, fast, and more human.</p>
          <Image src="/bg-pattern.png" alt="Pattern" className="mt-8 opacity-70 rounded-xl" width={300} height={200} />
        </div>

        {/* Right panel */}
        <div className="w-1/2 p-10 flex flex-col justify-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-6">Sign In to NeoBook</h2>
          <input
            type="text"
            placeholder="Email address"
            className="p-3 border border-gray-300 rounded-lg mb-4 focus:outline-none focus:ring-2 focus:ring-indigo-400"
          />
          <input
            type="password"
            placeholder="Password"
            className="p-3 border border-gray-300 rounded-lg mb-4 focus:outline-none focus:ring-2 focus:ring-indigo-400"
          />
          <button className="bg-indigo-600 text-white font-semibold py-3 rounded-lg hover:bg-indigo-700 transition">
            Log In
          </button>
          <div className="mt-4 text-sm text-center">
            <a href="#" className="text-indigo-600 hover:underline">Forgot password?</a>
          </div>
          <hr className="my-6" />
          <button className="border border-indigo-600 text-indigo-600 font-semibold py-2 rounded-lg hover:bg-indigo-50 transition">
            Create New Account
          </button>
        </div>
      </div>
    </div>
  );
}
