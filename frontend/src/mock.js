// Mock data for autoclick dashboard
export const mockSites = [
  {
    id: '1',
    url: 'https://www.google.com',
    status: 'active',
    lastAccessed: '2025-01-27 14:30:15',
    successCount: 145,
    errorCount: 2
  },
  {
    id: '2', 
    url: 'https://www.github.com',
    status: 'active',
    lastAccessed: '2025-01-27 14:30:05',
    successCount: 132,
    errorCount: 0
  },
  {
    id: '3',
    url: 'https://www.stackoverflow.com',
    status: 'inactive',
    lastAccessed: '2025-01-27 14:29:55',
    successCount: 98,
    errorCount: 5
  }
];

export const mockLogs = [
  {
    id: '1',
    timestamp: '2025-01-27 14:30:15',
    type: 'success',
    message: 'Successfully opened and closed https://www.google.com',
    duration: '2.3s'
  },
  {
    id: '2',
    timestamp: '2025-01-27 14:30:05',
    type: 'success', 
    message: 'Successfully opened and closed https://www.github.com',
    duration: '1.8s'
  },
  {
    id: '3',
    timestamp: '2025-01-27 14:29:55',
    type: 'error',
    message: 'Failed to load https://www.stackoverflow.com - Timeout after 30s',
    duration: '30.0s'
  },
  {
    id: '4',
    timestamp: '2025-01-27 14:29:45',
    type: 'success',
    message: 'Successfully opened and closed https://www.google.com',
    duration: '1.9s'
  },
  {
    id: '5',
    timestamp: '2025-01-27 14:29:35',
    type: 'info',
    message: 'Autoclick service started with 3 sites and 10s interval',
    duration: '-'
  }
];

export const mockConfig = {
  isRunning: true,
  interval: 10,
  timeout: 30,
  totalSites: 3,
  activeSites: 2,
  totalSuccess: 375,
  totalErrors: 7,
  uptime: '2h 15m'
};