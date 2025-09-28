import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { Separator } from './ui/separator';
import { ScrollArea } from './ui/scroll-area';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Play, Pause, Plus, Trash2, Settings, Activity, Globe, Clock, AlertCircle, CheckCircle, Info } from 'lucide-react';
import { mockSites, mockLogs, mockConfig } from '../mock';
import SiteManager from './SiteManager';
import LogViewer from './LogViewer';
import ConfigPanel from './ConfigPanel';

const Dashboard = () => {
  const [config, setConfig] = useState(mockConfig);
  const [sites, setSites] = useState(mockSites);
  const [logs, setLogs] = useState(mockLogs);
  const [activeTab, setActiveTab] = useState('overview');

  // Mock real-time updates
  useEffect(() => {
    const interval = setInterval(() => {
      if (config.isRunning) {
        // Simulate new log entries
        const newLog = {
          id: Date.now().toString(),
          timestamp: new Date().toLocaleString('pt-BR'),
          type: Math.random() > 0.8 ? 'error' : 'success',
          message: Math.random() > 0.8 
            ? `Failed to load ${sites[Math.floor(Math.random() * sites.length)]?.url} - Connection error`
            : `Successfully opened and closed ${sites[Math.floor(Math.random() * sites.length)]?.url}`,
          duration: `${(Math.random() * 3 + 1).toFixed(1)}s`
        };
        setLogs(prev => [newLog, ...prev.slice(0, 49)]); // Keep last 50 logs
        
        // Update uptime
        setConfig(prev => ({
          ...prev,
          totalSuccess: prev.totalSuccess + (newLog.type === 'success' ? 1 : 0),
          totalErrors: prev.totalErrors + (newLog.type === 'error' ? 1 : 0)
        }));
      }
    }, config.interval * 1000);

    return () => clearInterval(interval);
  }, [config.isRunning, config.interval, sites]);

  const toggleService = () => {
    setConfig(prev => ({ ...prev, isRunning: !prev.isRunning }));
  };

  const updateConfig = (newConfig) => {
    setConfig(prev => ({ ...prev, ...newConfig }));
  };

  const addSite = (url) => {
    const newSite = {
      id: Date.now().toString(),
      url: url,
      status: 'active',
      lastAccessed: '-',
      successCount: 0,
      errorCount: 0
    };
    setSites(prev => [...prev, newSite]);
    setConfig(prev => ({ ...prev, totalSites: prev.totalSites + 1, activeSites: prev.activeSites + 1 }));
  };

  const removeSite = (id) => {
    setSites(prev => prev.filter(site => site.id !== id));
    setConfig(prev => ({ ...prev, totalSites: prev.totalSites - 1, activeSites: prev.activeSites - 1 }));
  };

  const toggleSiteStatus = (id) => {
    setSites(prev => prev.map(site => {
      if (site.id === id) {
        const newStatus = site.status === 'active' ? 'inactive' : 'active';
        return { ...site, status: newStatus };
      }
      return site;
    }));
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <h1 className="text-3xl font-bold tracking-tight text-slate-900">AutoClick Dashboard</h1>
            <p className="text-slate-600">Gerencie sites e monitore atividades automatizadas</p>
          </div>
          <div className="flex items-center gap-3">
            <Badge variant={config.isRunning ? 'default' : 'secondary'} className="px-3 py-1">
              {config.isRunning ? (
                <><Play size={12} className="mr-1" /> Executando</>
              ) : (
                <><Pause size={12} className="mr-1" /> Pausado</>
              )}
            </Badge>
            <Button 
              onClick={toggleService}
              variant={config.isRunning ? 'destructive' : 'default'}
              size="lg"
            >
              {config.isRunning ? (
                <><Pause size={16} className="mr-2" /> Parar Serviço</>
              ) : (
                <><Play size={16} className="mr-2" /> Iniciar Serviço</>
              )}
            </Button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Sites Ativos</CardTitle>
              <Globe className="h-4 w-4 text-emerald-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-emerald-600">{config.activeSites}</div>
              <p className="text-xs text-slate-600">de {config.totalSites} configurados</p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Sucessos</CardTitle>
              <CheckCircle className="h-4 w-4 text-green-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{config.totalSuccess}</div>
              <p className="text-xs text-slate-600">acessos concluídos</p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Erros</CardTitle>
              <AlertCircle className="h-4 w-4 text-red-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">{config.totalErrors}</div>
              <p className="text-xs text-slate-600">falhas registradas</p>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Tempo Ativo</CardTitle>
              <Clock className="h-4 w-4 text-blue-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-blue-600">{config.uptime}</div>
              <p className="text-xs text-slate-600">intervalo: {config.interval}s</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full grid-cols-4">
            <TabsTrigger value="overview">Visão Geral</TabsTrigger>
            <TabsTrigger value="sites">Gerenciar Sites</TabsTrigger>
            <TabsTrigger value="logs">Logs</TabsTrigger>
            <TabsTrigger value="config">Configurações</TabsTrigger>
          </TabsList>
          
          <TabsContent value="overview" className="space-y-4">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Globe size={20} />
                    Sites Configurados
                  </CardTitle>
                  <CardDescription>Lista de sites sendo monitorados</CardDescription>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-2">
                      {sites.map((site) => (
                        <div key={site.id} className="flex items-center justify-between p-3 border rounded-lg">
                          <div className="flex-1">
                            <p className="font-medium text-sm truncate">{site.url}</p>
                            <p className="text-xs text-slate-600">Último acesso: {site.lastAccessed}</p>
                          </div>
                          <Badge variant={site.status === 'active' ? 'default' : 'secondary'}>
                            {site.status === 'active' ? 'Ativo' : 'Inativo'}
                          </Badge>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
              
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Activity size={20} />
                    Logs Recentes
                  </CardTitle>
                  <CardDescription>Últimas atividades do sistema</CardDescription>
                </CardHeader>
                <CardContent>
                  <ScrollArea className="h-64">
                    <div className="space-y-2">
                      {logs.slice(0, 8).map((log) => (
                        <div key={log.id} className="flex items-start gap-3 p-2 border rounded-lg">
                          {log.type === 'success' && <CheckCircle size={16} className="text-green-600 mt-0.5" />}
                          {log.type === 'error' && <AlertCircle size={16} className="text-red-600 mt-0.5" />}
                          {log.type === 'info' && <Info size={16} className="text-blue-600 mt-0.5" />}
                          <div className="flex-1 min-w-0">
                            <p className="text-sm truncate">{log.message}</p>
                            <p className="text-xs text-slate-600">{log.timestamp} • {log.duration}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </ScrollArea>
                </CardContent>
              </Card>
            </div>
          </TabsContent>
          
          <TabsContent value="sites">
            <SiteManager 
              sites={sites}
              onAddSite={addSite}
              onRemoveSite={removeSite}
              onToggleStatus={toggleSiteStatus}
            />
          </TabsContent>
          
          <TabsContent value="logs">
            <LogViewer logs={logs} />
          </TabsContent>
          
          <TabsContent value="config">
            <ConfigPanel config={config} onUpdateConfig={updateConfig} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default Dashboard;