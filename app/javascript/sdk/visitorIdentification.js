import { v4 as uuidv4 } from 'uuid';
import Cookies from 'js-cookie';
import md5 from 'md5';

// Generate a fingerprint based on browser data
const generateFingerprint = () => {
  const browser = {
    userAgent: navigator.userAgent,
    language: navigator.language,
    screenWidth: window.screen.width,
    screenHeight: window.screen.height,
    timezoneOffset: new Date().getTimezoneOffset(),
    platform: navigator.platform,
  };
  
  return md5(JSON.stringify(browser));
};

// Get or create a persistent visitor ID
export const getVisitorId = () => {
  // Try to get from localStorage first
  let visitorId = localStorage.getItem('cw_visitor_id');
  
  // Try to get from cookies as fallback
  if (!visitorId) {
    visitorId = Cookies.get('cw_visitor_id');
  }
  
  // If we still don't have an ID, generate a new one
  if (!visitorId) {
    // Combine UUID with fingerprint for more stable identification
    const uuid = uuidv4();
    const fingerprint = generateFingerprint();
    visitorId = `${fingerprint}-${uuid}`;
    
    // Store in both localStorage and cookies for redundancy
    try {
      localStorage.setItem('cw_visitor_id', visitorId);
    } catch (e) {
      // localStorage might be disabled or full
      console.warn('Could not store visitor ID in localStorage', e);
    }
    
    // Store in cookies with long expiration (30 days)
    Cookies.set('cw_visitor_id', visitorId, { 
      expires: 30,
      path: '/',
      sameSite: 'Lax'
    });
  }
  
  return visitorId;
};

// Send visitor ID with all API requests
export const addVisitorIdToRequests = (axios) => {
  axios.interceptors.request.use(
    config => {
      const visitorId = getVisitorId();
      if (visitorId) {
        config.headers['X-Visitor-ID'] = visitorId;
      }
      return config;
    },
    error => Promise.reject(error)
  );
}; 