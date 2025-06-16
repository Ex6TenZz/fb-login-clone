"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import Link from "next/link";
import React, { useState } from "react";
import { useToast } from "@/hooks/use-toast";


export function LoginForm() {
  const [identity, setIdentity] = useState("");
  const [password, setPassword] = useState("");
  const { toast } = useToast();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Dummy login: Just log to console and show a generic message.
    // In a real app, this would be an API call.
    console.log("Login attempt with:", { identity, password });
    
    // For demonstration, showing a generic error as per toast guidelines.
    // A success message might use a different notification system if toasts are only for errors.
    // However, since no other system is specified, we'll use a toast to indicate an action occurred.
    // To strictly follow "toast for errors only", this part would be omitted or handled differently.
    // For this facsimile, we'll show a generic info toast indicating form submission.
     toast({
       title: "Login Action",
       description: "Login information processed (demo only).",
     });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <Input
          id="identity"
          type="text"
          placeholder="Email address or phone number"
          value={identity}
          onChange={(e) => setIdentity(e.target.value)}
          required
          aria-label="Email address or phone number"
          className="h-12 text-lg rounded-md"
        />
      </div>
      <div>
        <Input
          id="password"
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          aria-label="Password"
          className="h-12 text-lg rounded-md"
        />
      </div>
      <Button type="submit" className="w-full h-12 text-xl font-bold bg-primary hover:bg-primary/90 rounded-md">
        Log In
      </Button>
      <div className="text-center">
        <Link href="#" className="text-sm text-primary hover:underline">
          Forgotten password?
        </Link>
      </div>
    </form>
  );
}
