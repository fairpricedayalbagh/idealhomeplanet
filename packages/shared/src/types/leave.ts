export interface ApplyLeaveRequest {
  leaveType: "SICK" | "CASUAL" | "PAID" | "UNPAID";
  startDate: string;
  endDate: string;
  reason: string;
}

export interface ReviewLeaveRequest {
  status: "APPROVED" | "REJECTED";
  reviewNote?: string;
}
