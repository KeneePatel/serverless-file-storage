"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { signOut } from "@/lib/auth"
import { useRouter } from "next/navigation"
import { Avatar, AvatarFallback } from "../ui/avatar"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "../ui/tooltip"

export function NavBar() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [userEmail, setUserEmail] = useState("")
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem("token")
    const email = localStorage.getItem("userEmail")
    setIsAuthenticated(!!token)
    if (email) setUserEmail(email)
  }, [userEmail])

  const handleSignOut = async () => {
    await signOut()
    setIsAuthenticated(false)
    setUserEmail("")
    localStorage.removeItem("userEmail")
    router.push("/auth/signin")
  }

  const getInitial = (email: string) => {
    return email ? email[0].toUpperCase() : "?"
  }

  return (
    <nav className="bg-primary text-primary-foreground">
      <div className="flex h-16 items-center px-4">
        <div className="flex w-full justify-between items-center">
          <div className="flex items-center space-x-4">
            <Link href="/" className="font-bold text-xl">
              File Storage
            </Link>
            {isAuthenticated && (
              <Link href="/dashboard" className="text-sm font-medium hover:text-primary-foreground/80">
                Dashboard
              </Link>
            )}
          </div>

          <div className="flex items-center space-x-4">
            {!isAuthenticated ? (
              <>
                <Link href="/auth/signin">
                  <Button variant="default" className="hover:text-secondary-foreground hover:bg-secondary">Sign In</Button>
                </Link>
                <Link href="/auth/signup">
                  <Button variant="outline" className="text-primary hover:text-primary-foreground hover:bg-primary/80">Sign Up</Button>
                </Link>
              </>
            ) : (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="flex items-center justify-center p-6 space-x-2 hover:bg-primary-foreground/20 hover:text-primary-foreground">
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Avatar className="w-8 h-8 text-primary">
                            <AvatarFallback>{getInitial(userEmail)}</AvatarFallback>
                          </Avatar>
                        </TooltipTrigger>
                          <span>Account</span>
                        <TooltipContent>
                          <p>{userEmail}</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>  
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onClick={handleSignOut}>
                    Sign Out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}
