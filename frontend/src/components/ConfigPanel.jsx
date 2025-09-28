import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Separator } from './ui/separator';
import { Settings, Save, RotateCcw, Clock, Timer, Globe } from 'lucide-react';
import { useToast } from '../hooks/use-toast';

const ConfigPanel = ({ config, onUpdateConfig }) => {
  const [localConfig, setLocalConfig] = useState({
    interval: config.interval,
    timeout: config.timeout,
    maxRetries: 3,
    userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  });
  const { toast } = useToast();

  const handleSaveConfig = () => {
    if (localConfig.interval < 5) {
      toast({
        title: "Intervalo muito pequeno",
        description: "O intervalo mínimo é de 5 segundos",
        variant: "destructive"
      });
      return;
    }

    if (localConfig.timeout < 10) {
      toast({
        title: "Timeout muito pequeno",
        description: "O timeout mínimo é de 10 segundos",
        variant: "destructive"
      });
      return;
    }

    onUpdateConfig(localConfig);
    toast({
      title: "Configurações salvas",
      description: "As configurações foram aplicadas com sucesso",
    });
  };

  const handleResetConfig = () => {
    setLocalConfig({
      interval: 10,
      timeout: 30,
      maxRetries: 3,
      userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    });
    toast({
      title: "Configurações resetadas",
      description: "Valores padrão foram restaurados",
    });
  };

  return (
    <div className="space-y-6">
      {/* Timing Configuration */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock size={20} />
            Configurações de Tempo
          </CardTitle>
          <CardDescription>
            Configure os intervalos e timeouts do sistema
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="interval">Intervalo entre Acessos (segundos)</Label>
              <Input
                id="interval"
                type="number"
                min="5"
                value={localConfig.interval}
                onChange={(e) => setLocalConfig(prev => ({ ...prev, interval: parseInt(e.target.value) || 10 }))}
              />
              <p className="text-xs text-slate-600">Tempo de espera entre cada acesso aos sites</p>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="timeout">Timeout de Carregamento (segundos)</Label>
              <Input
                id="timeout"
                type="number"
                min="10"
                value={localConfig.timeout}
                onChange={(e) => setLocalConfig(prev => ({ ...prev, timeout: parseInt(e.target.value) || 30 }))}
              />
              <p className="text-xs text-slate-600">Tempo máximo para aguardar o carregamento</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Advanced Configuration */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings size={20} />
            Configurações Avançadas
          </CardTitle>
          <CardDescription>
            Configurações adicionais para o comportamento do sistema
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="maxRetries">Máximo de Tentativas</Label>
            <Input
              id="maxRetries"
              type="number"
              min="1"
              max="10"
              value={localConfig.maxRetries}
              onChange={(e) => setLocalConfig(prev => ({ ...prev, maxRetries: parseInt(e.target.value) || 3 }))}
            />
            <p className="text-xs text-slate-600">Número de tentativas antes de marcar como erro</p>
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="userAgent">User Agent</Label>
            <Input
              id="userAgent"
              value={localConfig.userAgent}
              onChange={(e) => setLocalConfig(prev => ({ ...prev, userAgent: e.target.value }))}
              className="font-mono text-sm"
            />
            <p className="text-xs text-slate-600">String de identificação do navegador</p>
          </div>
        </CardContent>
      </Card>

      {/* Current Status */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Timer size={20} />
            Status Atual
          </CardTitle>
          <CardDescription>
            Informações sobre a configuração em uso
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center p-4 bg-slate-50 rounded-lg">
              <Clock size={24} className="mx-auto mb-2 text-blue-600" />
              <p className="text-2xl font-bold text-blue-600">{config.interval}s</p>
              <p className="text-sm text-slate-600">Intervalo Atual</p>
            </div>
            
            <div className="text-center p-4 bg-slate-50 rounded-lg">
              <Timer size={24} className="mx-auto mb-2 text-orange-600" />
              <p className="text-2xl font-bold text-orange-600">{config.timeout}s</p>
              <p className="text-sm text-slate-600">Timeout Atual</p>
            </div>
            
            <div className="text-center p-4 bg-slate-50 rounded-lg">
              <Globe size={24} className="mx-auto mb-2 text-green-600" />
              <p className="text-2xl font-bold text-green-600">{config.totalSites}</p>
              <p className="text-sm text-slate-600">Sites Configurados</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Action Buttons */}
      <div className="flex justify-end gap-3">
        <Button variant="outline" onClick={handleResetConfig}>
          <RotateCcw size={16} className="mr-2" />
          Resetar Padrões
        </Button>
        <Button onClick={handleSaveConfig}>
          <Save size={16} className="mr-2" />
          Salvar Configurações
        </Button>
      </div>
    </div>
  );
};

export default ConfigPanel;