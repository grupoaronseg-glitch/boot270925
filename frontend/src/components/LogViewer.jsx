import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { ScrollArea } from './ui/scroll-area';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Activity, Search, Download, Filter, CheckCircle, AlertCircle, Info } from 'lucide-react';

const LogViewer = ({ logs }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');

  const filteredLogs = logs.filter(log => {
    const matchesSearch = log.message.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = filterType === 'all' || log.type === filterType;
    return matchesSearch && matchesFilter;
  });

  const getLogIcon = (type) => {
    switch (type) {
      case 'success':
        return <CheckCircle size={16} className="text-green-600" />;
      case 'error':
        return <AlertCircle size={16} className="text-red-600" />;
      case 'info':
        return <Info size={16} className="text-blue-600" />;
      default:
        return <Activity size={16} className="text-slate-600" />;
    }
  };

  const getLogBadgeVariant = (type) => {
    switch (type) {
      case 'success':
        return 'default';
      case 'error':
        return 'destructive';
      case 'info':
        return 'secondary';
      default:
        return 'outline';
    }
  };

  const exportLogs = () => {
    const dataStr = JSON.stringify(filteredLogs, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = `autoclick-logs-${new Date().toISOString().split('T')[0]}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
  };

  return (
    <div className="space-y-6">
      {/* Controls */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity size={20} />
            Log do Sistema
          </CardTitle>
          <CardDescription>
            Monitore todas as atividades e erros do autoclick
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4">
            <div className="relative flex-1">
              <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" />
              <Input 
                placeholder="Buscar nos logs..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9"
              />
            </div>
            <Select value={filterType} onValueChange={setFilterType}>
              <SelectTrigger className="w-48">
                <Filter size={16} className="mr-2" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos os logs</SelectItem>
                <SelectItem value="success">Apenas sucessos</SelectItem>
                <SelectItem value="error">Apenas erros</SelectItem>
                <SelectItem value="info">Apenas informações</SelectItem>
              </SelectContent>
            </Select>
            <Button variant="outline" onClick={exportLogs}>
              <Download size={16} className="mr-2" />
              Exportar
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Logs Display */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Registros de Atividade</CardTitle>
              <CardDescription>
                {filteredLogs.length} entradas {searchTerm && `(filtradas de ${logs.length})`}
              </CardDescription>
            </div>
            <div className="flex gap-2">
              <Badge variant="outline">
                {logs.filter(l => l.type === 'success').length} sucessos
              </Badge>
              <Badge variant="destructive">
                {logs.filter(l => l.type === 'error').length} erros
              </Badge>
              <Badge variant="secondary">
                {logs.filter(l => l.type === 'info').length} informações
              </Badge>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {filteredLogs.length === 0 ? (
            <div className="text-center py-8">
              <Activity size={48} className="mx-auto text-slate-400 mb-4" />
              <p className="text-slate-600">Nenhum log encontrado</p>
              <p className="text-sm text-slate-500">
                {searchTerm ? 'Tente ajustar os filtros de busca' : 'Os logs aparecerão aqui quando o serviço estiver ativo'}
              </p>
            </div>
          ) : (
            <ScrollArea className="h-96">
              <div className="space-y-2">
                {filteredLogs.map((log) => (
                  <div key={log.id} className="flex items-start gap-3 p-3 border rounded-lg hover:bg-slate-50 transition-colors">
                    {getLogIcon(log.type)}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <Badge variant={getLogBadgeVariant(log.type)} className="text-xs">
                          {log.type.toUpperCase()}
                        </Badge>
                        <span className="text-xs text-slate-600">{log.timestamp}</span>
                        <span className="text-xs text-slate-500">• {log.duration}</span>
                      </div>
                      <p className="text-sm break-all">{log.message}</p>
                    </div>
                  </div>
                ))}
              </div>
            </ScrollArea>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default LogViewer;