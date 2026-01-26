import { Router } from "express";
import { validate } from "@src/middlewares/ValidateResource";
import { authenticate } from "@src/middlewares/authProvider.middleware";
import { loginSchema } from "@src/validators";
import {
  loginController,
  logoutController,
  getMeController,
} from "@src/controllers/auth.controller";

const router = Router();

router.post("/login", validate(loginSchema), loginController);

router.post("/logout", authenticate, logoutController);

router.get("/me", authenticate, getMeController);

export default router