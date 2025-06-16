// src/pages/index.tsx
import Head from "next/head";
import Image from "next/image";

export default function LoginPage() {
  return (
    <>
      <Head>
        <title>Login • NeoBook</title>
      </Head>
      <div className="min-h-screen bg-[#f0f2f5] flex items-center justify-center px-4">
        <div className="flex flex-col items-center w-full max-w-md bg-white p-8 rounded-lg shadow-md">
          <Image src="/logo.svg" alt="NeoBook" width={60} height={60} />
          <h1 className="text-2xl font-bold text-gray-800 mt-4 mb-6">Log in to NeoBook</h1>

          <form className="w-full space-y-4">
            <input
              type="text"
              placeholder="Email or phone number"
              className="w-full px-4 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-600"
            />
            <input
              type="password"
              placeholder="Password"
              className="w-full px-4 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-600"
            />
            <button
              type="submit"
              className="w-full bg-blue-600 text-white font-semibold py-2 rounded hover:bg-blue-700"
            >
              Log In
            </button>
            <div className="text-center text-sm text-blue-600 hover:underline cursor-pointer">
              Forgotten password?
            </div>
            <div className="border-t pt-4">
              <button
                type="button"
                className="bg-green-500 text-white py-2 px-6 rounded font-bold hover:bg-green-600"
              >
                Create New Account
              </button>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}
