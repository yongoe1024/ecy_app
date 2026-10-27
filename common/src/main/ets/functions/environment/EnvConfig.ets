export const envConfig: Record<string, AppConfig> = {
  'DEV': {
    //本机IP http://10.0.2.2:8080
    baseUrl: 'https://api-dev.xxx.com',
  },
  'TEST': {
    baseUrl: 'https://api-test.xxx.com',
  },
  'PROD': {
    baseUrl: 'https://api-prod.xxx.com',
  },
};

export interface AppConfig {
  baseUrl: string;
}


