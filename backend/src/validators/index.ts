export enum UserType {
  ADMIN = 'ADMIN',
  DOCTOR = 'DOCTOR',
  PATIENT = 'PATIENT',
}

export interface JWTPayload {
  user_id: string;
  user_type: UserType;
}

export enum therapy_drug {
  WARFARIN = "Warfarin",
  HEPARIN = "Heparin",
  DABIGATRAN = "Dabigatran",
  RIVAROXABAN = "Rivaroxaban",
  ACITROM = "ACITROM",
}


export { loginSchema } from './user.validator'
