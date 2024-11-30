// src/components/ui/button.jsx
import { forwardRef } from 'react'
import { clsx } from 'clsx'

const Button = forwardRef(({ className, children, ...props }, ref) => {
  return (
    <button
      className={clsx(
        "inline-flex items-center justify-center rounded-md font-medium",
        "px-4 py-2 text-sm",
        "bg-blue-600 text-white hover:bg-blue-700",
        "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        className
      )}
      ref={ref}
      {...props}
    >
      {children}
    </button>
  )
})

Button.displayName = "Button"
export { Button }
