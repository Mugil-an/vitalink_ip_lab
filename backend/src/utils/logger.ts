import { config } from '@alias/config'
import { createLogger, format, transports } from 'winston'

const logFormat = format.printf(({ level, message, timestamp }) => {
  return `${timestamp} [${level}]: ${message}`;
});

const logger = createLogger({
  level: config.logLevel,
  format: format.combine(format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }), format.json()),
  transports: [
    new transports.Console({ format: format.combine(format.colorize(), logFormat) })
  ]
})

export default logger
