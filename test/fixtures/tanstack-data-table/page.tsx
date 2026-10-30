// shadcn/ui data-table guide pattern (TanStack Table v8): https://ui.shadcn.com/docs/components/radix/data-table
import { columns } from "./columns"
import { DataTable } from "./data-table"

const payments = [
  { id: "m5gr84i9", amount: 316, status: "success", email: "ken99@example.com" },
  { id: "3u1reuv4", amount: 242, status: "success", email: "Abe45@example.com" },
  { id: "derv1ws0", amount: 837, status: "processing", email: "Monserrat44@example.com" },
  { id: "5kma53ae", amount: 874, status: "success", email: "Silas22@example.com" },
  { id: "bhqecj4p", amount: 721, status: "failed", email: "carmella@example.com" },
  { id: "p0r8wq1n", amount: 120, status: "pending", email: "zoe@example.com" },
  { id: "x7c2kd9e", amount: 455, status: "failed", email: "lena@example.com" },
  { id: "q3m6ta2v", amount: 89, status: "success", email: "omar@example.com" },
  { id: "h1j4tz8b", amount: 610, status: "processing", email: "ivy@example.com" },
  { id: "w9e3ru5y", amount: 333, status: "pending", email: "noah@example.com" },
  { id: "k2s7pl6m", amount: 978, status: "success", email: "mia@example.com" },
  { id: "g5f1nb3c", amount: 47, status: "failed", email: "leo@example.com" },
]

export default function PaymentsPage() {
  return (
    <div className="container mx-auto py-10">
      <DataTable columns={columns} data={payments} />
    </div>
  )
}
