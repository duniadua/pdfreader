/**
 * Setup Remote Config parameters for rate limiting
 * Run: node functions/setup-remoteconfig.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'pdfreader-8405a'
});

const remoteConfig = admin.remoteConfig();

async function setupRemoteConfig() {
  console.log('🔧 Setting up Remote Config for rate limiting...\n');

  // Get current template
  const template = await remoteConfig.getTemplate();
  console.log('📋 Current template version:', template.version?.versionNumber || 'undefined');

  // Define parameters to add
  const parameters = [
    {
      name: 'rate_limit_enabled',
      defaultValue: { value: 'true' },
      description: 'Master switch to enable/disable rate limiting globally'
    },
    {
      name: 'rate_limit_summarize_hourly',
      defaultValue: { value: '10' },
      description: 'Maximum summarize requests per hour per user'
    },
    {
      name: 'rate_limit_summarize_daily',
      defaultValue: { value: '50' },
      description: 'Maximum summarize requests per day per user'
    },
    {
      name: 'rate_limit_summarize_interval',
      defaultValue: { value: '2000' },
      description: 'Minimum milliseconds between summarize requests (2 seconds)'
    },
    {
      name: 'rate_limit_chat_hourly',
      defaultValue: { value: '30' },
      description: 'Maximum chat requests per hour per user'
    },
    {
      name: 'rate_limit_chat_daily',
      defaultValue: { value: '200' },
      description: 'Maximum chat requests per day per user'
    },
    {
      name: 'rate_limit_chat_interval',
      defaultValue: { value: '2000' },
      description: 'Minimum milliseconds between chat requests (2 seconds)'
    },
    {
      name: 'rate_limit_extract_hourly',
      defaultValue: { value: '15' },
      description: 'Maximum extract requests per hour per user'
    },
    {
      name: 'rate_limit_extract_daily',
      defaultValue: { value: '75' },
      description: 'Maximum extract requests per day per user'
    },
    {
      name: 'rate_limit_extract_interval',
      defaultValue: { value: '2000' },
      description: 'Minimum milliseconds between extract requests (2 seconds)'
    }
  ];

  // Add parameters to template
  for (const param of parameters) {
    const existingParam = template.parameters?.find(p => p.name === param.name);
    if (!existingParam) {
      template.parameters = template.parameters || [];
      template.parameters.push({
        name: param.name,
        defaultValue: param.defaultValue,
        description: param.description,
        valueType: param.name === 'rate_limit_enabled' ? 'BOOLEAN' : 'NUMBER'
      });
      console.log(`✅ Added parameter: ${param.name}`);
    } else {
      console.log(`⏭️  Parameter already exists: ${param.name}`);
    }
  }

  // Publish the template
  console.log('\n📤 Publishing template...');
  const publishedTemplate = await remoteConfig.publishTemplate(template);

  console.log(`\n✅ Remote Config setup complete!`);
  console.log(`📊 Template version: ${publishedTemplate.version.versionNumber}`);
  console.log(`🕐 Updated at: ${publishedTemplate.version.updateTime}`);

  console.log('\n🎉 Rate limiting parameters are now active!');
  console.log('You can change them anytime at: https://console.firebase.google.com/project/pdfreader-8405a/remote-config');

  process.exit(0);
}

setupRemoteConfig().catch((error) => {
  console.error('❌ Error setting up Remote Config:', error);
  process.exit(1);
});
