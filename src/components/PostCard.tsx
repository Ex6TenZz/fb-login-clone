// src/components/PostCard.tsx
export default function PostCard({ user, content }) {
  return (
    <div className="bg-white p-4 rounded-xl shadow-md mb-4">
      <div className="flex items-center mb-2">
        <img src={user.avatar} className="w-10 h-10 rounded-full mr-3" />
        <div>
          <p className="font-semibold">{user.name}</p>
          <p className="text-xs text-gray-500">Just now</p>
        </div>
      </div>
      <p>{content}</p>
    </div>
  );
}
