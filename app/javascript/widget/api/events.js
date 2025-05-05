import { API } from 'widget/helpers/axios';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';

export const generateEventParams = () => {
  // Get all available page information
  const currentPageUrl = window.location.href || document.URL || '';
  const currentPageTitle = document.title || '';
  const referrerUrl = window.referrerURL || document.referrer || '';
  
  return {
    initiated_at: {
      timestamp: new Date().toString(),
    },
    referer: referrerUrl,
    page_url: currentPageUrl,
    page_title: currentPageTitle,
    page_info: {
      pathname: window.location.pathname || '',
      hostname: window.location.hostname || '',
      search: window.location.search || '',
      hash: window.location.hash || ''
    },
    browser_info: {
      language: navigator.language || '',
      user_agent: navigator.userAgent || '',
      screen_resolution: `${window.screen.width}x${window.screen.height}` || ''
    }
  };
};

export default {
  create(name) {
    const search = buildSearchParamsWithLocale(window.location.search);
    return API.post(`/api/v1/widget/events${search}`, {
      name,
      event_info: generateEventParams(),
    });
  },
};
