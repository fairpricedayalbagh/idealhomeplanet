export interface MarkAttendanceRequest {
  qrToken: string;
  type: "CHECK_IN" | "CHECK_OUT";
  deviceId?: string;
}

export interface ManualAttendanceRequest {
  userId: string;
  type: "CHECK_IN" | "CHECK_OUT";
  timestamp: string;
  note: string;
}
