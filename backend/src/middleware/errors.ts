import type { ErrorRequestHandler } from 'express';

export class AppError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof AppError) {
    res.status(error.status).json({ error: { code: error.code, message: error.message } });
    return;
  }
  const status = error?.type === 'entity.too.large' ? 413
    : error?.type === 'entity.parse.failed' ? 400 : 500;
  res.status(status).json({ error: {
    code: status === 500 ? 'INTERNAL_ERROR' : 'INVALID_BODY',
    message: status === 500 ? 'No pudimos procesar la solicitud.' : 'El cuerpo JSON es inválido o demasiado grande.',
  } });
};
