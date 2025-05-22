export const buildSearchParamsWithLocale = search => {
  // [TODO] for now this works, but we will need to find a way to get the locale from the root component
  const locale = window.WOOT_WIDGET.$root.$i18n.locale;
  const params = new URLSearchParams(search);
  params.append('locale', locale);
  
  // If we have a stored conversation cookie in the store, use it in all API requests
  // This ensures we're always working with the same conversation across page navigations
  const conversationStore = window.WOOT_WIDGET.$store.state.conversation;
  if (conversationStore?.meta?.conversationCookie) {
    params.append('cw_conversation', conversationStore.meta.conversationCookie);
  }

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
