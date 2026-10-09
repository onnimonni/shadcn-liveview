import React from "react"
import { toast } from "sonner"
import { Button } from "../../vendor/shadcn/ui/button"
import { Input } from "../../vendor/shadcn/ui/input"
import { Toaster } from "../../vendor/shadcn/ui/sonner"
import { Pagination, PaginationContent, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "../../vendor/shadcn/ui/pagination"

export function ButtonPreview() {
  const [count, setCount] = React.useState(0)
  return <Button onClick={() => setCount(count + 1)}>{count ? `Clicked ${count} times` : "Click me"}</Button>
}

export function PaginationPreview() {
  const [page, setPage] = React.useState(1)
  const select = (event: React.MouseEvent, value: number) => { event.preventDefault(); setPage(value) }
  return <Pagination><PaginationContent>
    <PaginationItem><PaginationPrevious href="#page-1" onClick={event => select(event, Math.max(1, page - 1))} /></PaginationItem>
    {[1, 2, 3].map(value => <PaginationItem key={value}><PaginationLink href={`#page-${value}`} isActive={page === value} onClick={event => select(event, value)}>{value}</PaginationLink></PaginationItem>)}
    <PaginationItem><PaginationNext href="#page-3" onClick={event => select(event, Math.min(3, page + 1))} /></PaginationItem>
  </PaginationContent></Pagination>
}

export function NotificationPreview() {
  return <><form className="grid gap-2" onSubmit={event => {
    event.preventDefault()
    const submitter = (event.nativeEvent as SubmitEvent).submitter as HTMLButtonElement
    const data = new FormData(event.currentTarget)
    toast(String(data.get("message")), { description: "Your changes were saved.", duration: submitter.value === "0" ? Infinity : 1000, closeButton: true })
  }}><Input name="message" aria-label="Notification message" defaultValue="Event has been created" />
    <Button type="submit" value="0">Show notification</Button>
    <Button type="submit" value="1000">Show brief notification</Button>
  </form><Toaster /></>
}
