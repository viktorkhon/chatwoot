export const buildSearchParamsWithLocale = search => {
  // [TODO] for now this works, but we will need to find a way to get the locale from the root component
  let locale = 'en'; // Default fallback locale
  
  try {
    // Safely access the locale with fallbacks
    if (window.WOOT_WIDGET && window.WOOT_WIDGET.$root && window.WOOT_WIDGET.$root.$i18n) {
      locale = window.WOOT_WIDGET.$root.$i18n.locale;
    } else if (window.WOOT_WIDGET && window.WOOT_WIDGET.locale) {
      locale = window.WOOT_WIDGET.locale;
    } else if (navigator.language) {
      // Use browser language as fallback
      locale = navigator.language.split('-')[0];
    }
  } catch (error) {
    console.warn('[Chatwoot] Could not determine locale, using default:', error);
    locale = 'en';
  }
  
  const params = new URLSearchParams(search);
  params.append('locale', locale);

  return `?${params}`;
};

export const getLocale = (search = '') => {
  return new URLSearchParams(search).get('locale');
};

export const buildPopoutURL = ({
  origin,
  conversationCookie,
  websiteToken,
  locale,
}) => {
  const popoutUrl = new URL('/widget', origin);
  popoutUrl.searchParams.append('cw_conversation', conversationCookie);
  popoutUrl.searchParams.append('website_token', websiteToken);
  popoutUrl.searchParams.append('locale', locale);

  return popoutUrl.toString();
};
