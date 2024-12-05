"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import Link from "next/link";

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) {
      setIsAuthenticated(true);
    }
  }, []);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background p-8">
      <div className="max-w-3xl text-center space-y-8">
        <h1 className="text-4xl sm:text-6xl font-bold tracking-tight">
          Secure File Storage Solution
        </h1>

        <p className="text-xl text-muted-foreground">
          Store, manage and share your files securely in the cloud
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          {!isAuthenticated ? (
            <>
              <Link href="/auth/signup">
                <Button size="lg" className="w-full sm:w-auto">
                  Get Started
                </Button>
              </Link>
              <Link href="/auth/signin">
                <Button
                  variant="outline"
                  size="lg"
                  className="w-full sm:w-auto"
                >
                  Sign In
                </Button>
              </Link>
            </>
          ) : (
            <Link href="/dashboard">
              <Button size="lg">Go to Dashboard</Button>
            </Link>
          )}
        </div>
      </div>

      <div className="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-8 max-w-4xl">
        <div className="p-6 text-center space-y-3">
          <h2 className="text-xl font-semibold">Secure Storage</h2>
          <p className="text-muted-foreground">
            Your files are encrypted and stored securely in the cloud
          </p>
        </div>
        <div className="p-6 text-center space-y-3">
          <h2 className="text-xl font-semibold">Easy Sharing</h2>
          <p className="text-muted-foreground">
            Share files and folders with anyone, anywhere
          </p>
        </div>
        <div className="p-6 text-center space-y-3">
          <h2 className="text-xl font-semibold">Access Anywhere</h2>
          <p className="text-muted-foreground">
            Access your files from any device, anytime
          </p>
        </div>
      </div>
    </div>
  );
}
