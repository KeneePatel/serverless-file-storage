import * as fs from 'fs';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function generateEnvFile() {
  try {
    // Run terraform output command
    const { stdout } = await execAsync('terraform output -json frontend_env');
    const envVars = JSON.parse(stdout);

    // Create .env.local content
    let envContent = '# Auto-generated from Terraform outputs\n';
    for (const [key, value] of Object.entries(envVars)) {
      envContent += `${key}=${value}\n`;
    }

    // Write to .env.local
    fs.writeFileSync('../file-storage-frontend/.env.local', envContent);
    console.log('Successfully generated .env.local file');
  } catch (error) {
    console.error('Error generating env file:', error);
    process.exit(1);
  }
}

generateEnvFile();
