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
  }
  return config;
});

export const setHeader = (value, key = 'X-Auth-Token') => {
  API.defaults.headers.common[key] = value;
};

export const removeHeader = key => {
  delete API.defaults.headers.common[key];
};
