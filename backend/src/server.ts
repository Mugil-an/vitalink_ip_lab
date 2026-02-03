import 'module-alias/register';
import app from "./app";
import { config } from "./config";
import connectDB from "./config/db";
import logger from './utils/logger'

async function startServer() {
  const PORT = config.port;

  try {
    await connectDB().then(() => {
      app.listen(PORT, () => {
        logger.info(`Server is running on port ${PORT}`);
      });
    });
  }
  catch (err) {
    logger.error(`Error: ${(err as Error).message}`);
    process.exit(1);
  }
}

startServer();
