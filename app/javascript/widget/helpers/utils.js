import { WOOT_PREFIX } from './constants';

export const isEmptyObject = obj => {
  if (!obj) return true;
  return Object.keys(obj).length === 0 && obj.constructor === Object;
};

export const sendMessage = msg => {
  window.parent.postMessage(
    `chatwoot-widget:${JSON.stringify({ ...msg })}`,
    '*'
  );
};

// Generate a visitor ID for incognito users
export const generateVisitorId = () => {
  // Try to get existing visitor ID from sessionStorage first
  let visitorId = sessionStorage.getItem('cw_visitor_id');

  if (!visitorId) {
    // Generate a new visitor ID using timestamp and random number
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 15);
    visitorId = `visitor_${timestamp}_${random}`;

    // Store in sessionStorage so it persists across page navigation in the same session
    sessionStorage.setItem('cw_visitor_id', visitorId);
  }

  return visitorId;
};

// Get the current visitor ID
export const getVisitorId = () => {
  const visitorId = sessionStorage.getItem('cw_visitor_id') || generateVisitorId();
  return visitorId;
};

export const IFrameHelper = {
  isIFrame: () => window.self !== window.top,
  sendMessage,
  isAValidEvent: e => {
    const isDataAString = typeof e.data === 'string';
    return isDataAString && e.data.indexOf(WOOT_PREFIX) === 0;
  },
  getMessage: e => JSON.parse(e.data.replace(WOOT_PREFIX, '')),
};
export const RNHelper = {
  isRNWebView: () => window.ReactNativeWebView,
  sendMessage: msg => {
    window.ReactNativeWebView.postMessage(
      `chatwoot-widget:${JSON.stringify({ ...msg })}`
    );
  },
};

export const groupBy = (array, predicate) => {
  return array.reduce((acc, value) => {
    (acc[predicate(value)] ||= []).push(value);
    return acc;
  }, {});
};
