import * as React from "react"

export const Portal = React.forwardRef(function Portal(
  props: { children?: React.ReactNode; [key: string]: unknown },
  _ref: React.ForwardedRef<unknown>
) {
  return <>{props.children}</>
})

export const Root = Portal
