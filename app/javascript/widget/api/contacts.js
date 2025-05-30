import { API } from 'widget/helpers/axios';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';
import { getVisitorId } from '../helpers/utils';

const buildUrl = endPoint => `/api/v1/${endPoint}${buildSearchParamsWithLocale(window.location.search)}`;

const buildParams = (additionalParams = {}) => {
  const visitorId = getVisitorId();
  return {
    visitor_id: visitorId,
    ...additionalParams
  };
};

export default {
  get() {
    return API.get(buildUrl('widget/contact'), {
      params: buildParams()
    });
  },
  update(userObject) {
    return API.patch(buildUrl('widget/contact'), {
      ...userObject,
      ...buildParams()
    });
  },
  setUser(identifier, userObject) {
    return API.patch(buildUrl('widget/contact/set_user'), {
      identifier,
      ...userObject,
      ...buildParams()
    });
  },
  setCustomAttributes(customAttributes = {}) {
    return API.patch(buildUrl('widget/contact'), {
      custom_attributes: customAttributes,
      ...buildParams()
    });
  },
  deleteCustomAttribute(customAttribute) {
    return API.post(buildUrl('widget/contact/destroy_custom_attributes'), {
      custom_attributes: [customAttribute],
      ...buildParams()
    });
  },
};
