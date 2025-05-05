import { API } from 'widget/helpers/axios';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';

export const generateEventParams = () => ({
  initiated_at: {
    timestamp: new Date().toString(),
  },
  referer: window.referrerURL || '',
  page_url: window.location.href || document.URL || '',
  page_title: document.title || '',
  page_info: {
    pathname: window.location.pathname || '',
    hostname: window.location.hostname || '',
    search: window.location.search || '',
    hash: window.location.hash || ''
  }
});

export default {
  create(name) {
    const search = buildSearchParamsWithLocale(window.location.search);
    return API.post(`/api/v1/widget/events${search}`, {
      name,
      event_info: generateEventParams(),
    });
  },
};
