// src/components/ui/input.jsx
import { forwardRef } from 'react'
import { clsx } from 'clsx'

const Input = forwardRef(({ className, ...props }, ref) => {
  return (
    <input
      className={clsx(
        "flex h-10 w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm",
        "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
        "disabled:cursor-not-allowed disabled:opacity-50",
        className
      )}
      ref={ref}
      {...props}
    />
  )
})

Input.displayName = "Input"
export { Input }
