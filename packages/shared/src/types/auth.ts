export interface LoginRequest {
  phone: string;
  pin: string;
}

export interface TokenPayload {
  userId: string;
  role: "ADMIN" | "EMPLOYEE";
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface RefreshRequest {
  refreshToken: string;
}
