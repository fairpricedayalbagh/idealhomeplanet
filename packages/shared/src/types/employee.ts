export interface CreateEmployeeRequest {
  name: string;
  phone: string;
  email?: string;
  pin: string;
  designation?: string;
  dateOfJoining?: string;
  dateOfBirth?: string;
  address?: string;
  emergencyName?: string;
  emergencyPhone?: string;
  bankAccount?: string;
  bankIfsc?: string;
  upiId?: string;
  salaryType: "MONTHLY" | "HOURLY";
  monthlySalary?: number;
  hourlyRate?: number;
  shiftStart?: string;
  shiftEnd?: string;
  graceMins?: number;
  weeklyOffDays?: number[];
  sickLeaveBalance?: number;
  casualLeaveBalance?: number;
  paidLeaveBalance?: number;
}

export interface UpdateEmployeeRequest extends Partial<CreateEmployeeRequest> {}
