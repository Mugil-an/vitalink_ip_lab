import 'dotenv/config'
import connectDB from '@src/config/db'
import { User, AdminProfile } from '@src/models'
import { UserType } from '@src/validators'
import logger from '@src/utils/logger'

async function main() {
  const loginId = process.argv[2] || process.env.ADMIN_LOGIN_ID
  const password = process.argv[3] || process.env.ADMIN_PASSWORD

  if (!loginId || !password) {
    console.error('Usage: ts-node src/scripts/createAdmin.ts <login_id> <password>')
    console.error('Or set ADMIN_LOGIN_ID and ADMIN_PASSWORD env vars')
    process.exit(1)
  }

  await connectDB()

  const existing = await User.findOne({ login_id: loginId })
  if (existing) {
    logger.warn(`User with login_id ${loginId} already exists; aborting`)
    process.exit(0)
  }

  const adminProfile = await AdminProfile.create({ permission: 'FULL_ACCESS' })
  await User.create({
    login_id: loginId,
    password,
    user_type: UserType.ADMIN,
    profile_id: adminProfile._id,
  })

  logger.info(`Admin user created: ${loginId}`)
  process.exit(0)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
