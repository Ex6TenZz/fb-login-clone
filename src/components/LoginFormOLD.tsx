// src/components/LoginForm.tsx

export default function LoginForm() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="flex flex-col md:flex-row items-center justify-between max-w-5xl w-full px-6">
        {/* Left Side */}
        <div className="md:w-1/2 mb-12 md:mb-0">
          <img src="/facebook-logo.svg" alt="Facebook" className="w-60 mb-6" />
          <h2 className="text-2xl md:text-3xl font-semibold text-gray-800">
            Facebook helps you connect and share with the people in your life.
          </h2>
          <img src="/facebook-network.png" alt="network" className="mt-8 w-64" />
        </div>

        {/* Right Side */}
        <div className="bg-white p-6 rounded-lg shadow-md w-full md:w-[400px]">
          <h3 className="text-xl font-bold mb-4">Login</h3>
          <input
            type="text"
            placeholder="Email or phone number"
            className="w-full mb-3 px-4 py-2 border border-gray-300 rounded-md focus:outline-none"
          />
          <input
            type="password"
            placeholder="Password"
            className="w-full mb-3 px-4 py-2 border border-gray-300 rounded-md focus:outline-none"
          />
          <button className="w-full bg-blue-600 text-white font-semibold py-2 rounded-md hover:bg-blue-700">
            Log In
          </button>
          <div className="text-center mt-3">
            <a href="#" className="text-blue-600 text-sm hover:underline">
              Forgotten password?
            </a>
          </div>
          <hr className="my-4" />
          <button className="w-full bg-green-600 text-white font-semibold py-2 rounded-md hover:bg-green-700">
            Create New Account
          </button>
          <p className="text-xs text-center mt-4">
            <a href="#" className="hover:underline">
              Create a Page
            </a>{" "}
            for a celebrity, band or business.
          </p>
        </div>
      </div>
    </div>
  );
}
