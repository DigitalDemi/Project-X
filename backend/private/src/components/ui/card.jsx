// src/components/ui/card.jsx
//
    //
import clsx from 'clsx'
export function Card({ className, children, ...props }) {
  return (
    <div
      className={clsx(
        "rounded-lg border border-gray-200 bg-white shadow-sm",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}

export function CardHeader({ className, ...props }) {
  return (
    <div
      className={clsx("flex flex-col space-y-1.5 p-6", className)}
      {...props}
    />
  )
}

export function CardTitle({ className, ...props }) {
  return (
    <h3
      className={clsx("text-lg font-semibold leading-none", className)}
      {...props}
    />
  )
}

export function CardContent({ className, ...props }) {
  return (
    <div className={clsx("p-6 pt-0", className)} {...props} />
  )
}
