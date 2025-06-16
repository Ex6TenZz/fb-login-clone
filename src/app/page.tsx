"use client";

import FacebookLogo from "@/components/facebook-logo";
import { LoginForm } from "@/components/login-form";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import Link from "next/link";

export default function Home() {
  return (
    <main className="bg-background min-h-screen flex flex-col items-center justify-center p-4 lg:p-8 font-body">
      <div className="flex flex-col lg:flex-row items-center lg:items-start justify-center lg:justify-between w-full max-w-6xl px-4">
        <div className="lg:w-[580px] lg:pr-8 xl:pr-12 pt-8 lg:pt-24 text-center lg:text-left mb-10 lg:mb-0">
          <FacebookLogo className="h-20 lg:h-[106px] text-primary mx-auto lg:mx-0 -ml-4 lg:-ml-7 mb-0 lg:mb-2" />
          <h2 className="text-2xl lg:text-[28px] leading-tight text-foreground/90 font-normal">
            Facebook helps you connect and share with the people in your life.
          </h2>
        </div>

        <div className="w-full max-w-md lg:w-[396px] mt-0 lg:mt-12">
          <Card className="shadow-xl rounded-lg">
            <CardContent className="p-4 space-y-4">
              <LoginForm />
              <Separator className="my-4 bg-border" />
              <Button
                variant="secondary"
                className="w-full h-12 text-lg font-bold bg-[#42b72a] hover:bg-[#36a420] text-white rounded-md"
                onClick={() => console.log("Create new account clicked (demo)")}
              >
                Create new account
              </Button>
            </CardContent>
          </Card>
          <p className="mt-7 text-center text-sm text-foreground">
            <Link href="#" className="font-semibold hover:underline">Create a Page</Link> for a celebrity, brand or business.
          </p>
        </div>
      </div>
      <div className="absolute bottom-8 text-center w-full">
        <p className="text-xs text-muted-foreground max-w-md mx-auto">
          <strong>Disclaimer:</strong> This is a clone of the Facebook login page created for educational and demonstration purposes only.
          It is not affiliated with, endorsed by, or connected to Facebook or Meta Platforms, Inc.
          Do not enter your actual Facebook credentials here.
        </p>
      </div>
    </main>
  );
}
