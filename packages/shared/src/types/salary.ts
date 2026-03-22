export interface GenerateSalaryRequest {
  month: number;
  year: number;
}

export interface MarkPaidRequest {
  paymentMode: "CASH" | "BANK" | "UPI";
}

export interface AddBonusRequest {
  amount: number;
  reason?: string;
}
