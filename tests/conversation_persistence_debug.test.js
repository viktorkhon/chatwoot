import { describe, it, expect, beforeEach, vi } from 'vitest';
import { generateVisitorId, getVisitorId } from './helpers/utils';

// Mock sessionStorage
const mockSessionStorage = {
  store: {},
  getItem: vi.fn((key) => mockSessionStorage.store[key] || null),
  setItem: vi.fn((key, value) => {
    mockSessionStorage.store[key] = value;
  }),
  removeItem: vi.fn((key) => {
    delete mockSessionStorage.store[key];
  }),
  clear: vi.fn(() => {
    mockSessionStorage.store = {};
  })
};

Object.defineProperty(window, 'sessionStorage', {
  value: mockSessionStorage
});

describe('Conversation Persistence Debug Tests', () => {
  beforeEach(() => {
    // Clear session storage before each test
    mockSessionStorage.clear();
    vi.clearAllMocks();
  });

  describe('Visitor ID Generation and Persistence', () => {
    it('should generate a visitor ID and store it in sessionStorage', () => {
      const visitorId = generateVisitorId();
      
      console.log('[🔍 Test Debug] Generated visitor ID:', visitorId);
      
      expect(visitorId).toBeDefined();
      expect(visitorId).toMatch(/^visitor_\d+_[a-z0-9]+$/);
      expect(mockSessionStorage.setItem).toHaveBeenCalledWith('cw_visitor_id', visitorId);
    });

    it('should return the same visitor ID on subsequent calls', () => {
      const firstVisitorId = generateVisitorId();
      const secondVisitorId = getVisitorId();
      
      console.log('[🔍 Test Debug] First visitor ID:', firstVisitorId);
      console.log('[🔍 Test Debug] Second visitor ID:', secondVisitorId);
      
      expect(firstVisitorId).toBe(secondVisitorId);
    });

    it('should persist visitor ID across page navigation simulation', () => {
      // Simulate first page load
      const visitorId1 = generateVisitorId();
      console.log('[🔍 Test Debug] Page 1 visitor ID:', visitorId1);
      
      // Simulate navigation to second page (sessionStorage persists)
      const visitorId2 = getVisitorId();
      console.log('[🔍 Test Debug] Page 2 visitor ID:', visitorId2);
      
      // Simulate navigation to third page
      const visitorId3 = getVisitorId();
      console.log('[🔍 Test Debug] Page 3 visitor ID:', visitorId3);
      
      expect(visitorId1).toBe(visitorId2);
      expect(visitorId2).toBe(visitorId3);
    });
  });

  describe('Conversation Flow Simulation', () => {
    it('should simulate the conversation creation and message sending flow', async () => {
      // Mock API responses
      const mockConversationResponse = {
        id: 123,
        contact_id: 456,
        inbox_id: 789,
        status: 'open',
        messages: [{
          id: 1,
          content: 'Hello',
          message_type: 0,
          conversation_id: 123
        }]
      };

      const mockMessageResponse = {
        id: 2,
        content: 'Test message',
        message_type: 0,
        conversation_id: 123,
        sender_type: 'Contact'
      };

      // Simulate visitor ID generation
      const visitorId = generateVisitorId();
      console.log('[🔍 Test Debug] Conversation flow visitor ID:', visitorId);

      // Simulate conversation creation
      console.log('[🔍 Test Debug] Simulating conversation creation...');
      console.log('[🔍 Test Debug] Mock conversation response:', mockConversationResponse);

      // Simulate message sending
      console.log('[🔍 Test Debug] Simulating message sending...');
      console.log('[🔍 Test Debug] Mock message response:', mockMessageResponse);

      // Simulate page navigation
      console.log('[🔍 Test Debug] Simulating page navigation...');
      const visitorIdAfterNavigation = getVisitorId();
      console.log('[🔍 Test Debug] Visitor ID after navigation:', visitorIdAfterNavigation);

      expect(visitorId).toBe(visitorIdAfterNavigation);
    });
  });

  describe('API Request Simulation', () => {
    it('should simulate API requests with visitor ID headers', () => {
      const visitorId = generateVisitorId();
      
      // Simulate conversation creation API call
      const conversationApiCall = {
        url: '/api/v1/widget/conversations',
        headers: {
          'X-Visitor-ID': visitorId
        },
        params: {
          visitor_id: visitorId,
          message: {
            content: 'Hello',
            page_url: 'https://example.com/page1',
            page_title: 'Page 1'
          }
        }
      };

      console.log('[🔍 Test Debug] Conversation API call:', conversationApiCall);

      // Simulate message sending API call
      const messageApiCall = {
        url: '/api/v1/widget/messages',
        headers: {
          'X-Visitor-ID': visitorId
        },
        params: {
          visitor_id: visitorId,
          message: {
            content: 'Second message',
            page_url: 'https://example.com/page2',
            page_title: 'Page 2'
          }
        }
      };

      console.log('[🔍 Test Debug] Message API call:', messageApiCall);

      expect(conversationApiCall.headers['X-Visitor-ID']).toBe(visitorId);
      expect(messageApiCall.headers['X-Visitor-ID']).toBe(visitorId);
      expect(conversationApiCall.params.visitor_id).toBe(visitorId);
      expect(messageApiCall.params.visitor_id).toBe(visitorId);
    });
  });
}); 