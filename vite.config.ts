import { defineConfig } from 'vite'
import clarusjs from 'clarusjs/vite'

// Local dev: load DATABASE_URL from .env (see .env.example). Existing env vars win, so
// the container's DATABASE_URL from Kubernetes is never overridden; no .env in the image.
try {
  process.loadEnvFile()
} catch {}

export default defineConfig({
  plugins: [clarusjs()],
  // In the cluster, `vite preview` serves real traffic. Staging is reached as
  // staging.<ip>.sslip.io (IP hosts are always allowed); add your domain here when there is one.
  preview: { allowedHosts: ['.sslip.io'] },
})
