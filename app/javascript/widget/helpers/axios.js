import axios from 'axios';
import { APP_BASE_URL } from 'widget/helpers/constants';
import { getVisitorId } from './utils';

export const API = axios.create({
  baseURL: APP_BASE_URL,
  withCredentials: false,
});

// Set visitor ID header for all requests
API.interceptors.request.use(config => {
  const visitorId = getVisitorId();
  if (visitorId) {
    config.headers['X-Visitor-ID'] = visitorId;
    console.log('[Chatwoot Debug] Axios: Adding X-Visitor-ID header:', visitorId, 'to', config.url);
  } else {
    console.warn('[Chatwoot Debug] Axios: No visitor ID available for request to', config.url);
  }
  return config;
});

// Add response interceptor to log API responses and errors
API.interceptors.response.use(
  response => {
    console.log('[Chatwoot Debug] Axios: Successful response from', response.config.url, ':', response.status);
    return response;
  },
  error => {
    console.error('[Chatwoot Debug] Axios: Error response from', error.config?.url, ':', error.response?.status || error.message);
    if (error.response?.status === 500) {
      console.error('[Chatwoot Debug] Axios: 500 Error details:', error.response.data);
    }
    return Promise.reject(error);
  }
);

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
