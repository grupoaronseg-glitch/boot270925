import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { ScrollArea } from './ui/scroll-area';
import { Plus, Trash2, Globe, Power, PowerOff } from 'lucide-react';
import { useToast } from '../hooks/use-toast';

const SiteManager = ({ sites, onAddSite, onRemoveSite, onToggleStatus }) => {
  const [newSiteUrl, setNewSiteUrl] = useState('');
  const { toast } = useToast();

  const handleAddSite = () => {
    if (!newSiteUrl.trim()) {
      toast({
        title: "URL inválida",
        description: "Por favor, insira uma URL válida",
        variant: "destructive"
      });
      return;
    }

    // Basic URL validation
    try {
      new URL(newSiteUrl);
    } catch {
      toast({
        title: "URL inválida", 
        description: "Por favor, insira uma URL válida (ex: https://example.com)",
        variant: "destructive"
      });
      return;
    }

    onAddSite(newSiteUrl);
    setNewSiteUrl('');
    toast({
      title: "Site adicionado",
      description: `${newSiteUrl} foi adicionado à lista`,
    });
  };

  const handleRemoveSite = (id, url) => {
    onRemoveSite(id);
    toast({
      title: "Site removido",
      description: `${url} foi removido da lista`,
    });
  };

  const handleToggleStatus = (id, url, currentStatus) => {
    onToggleStatus(id);
    const newStatus = currentStatus === 'active' ? 'inativo' : 'ativo';
    toast({
      title: "Status alterado",
      description: `${url} está agora ${newStatus}`,
    });
  };

  return (
    <div className="space-y-6">
      {/* Add New Site */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Plus size={20} />
            Adicionar Novo Site
          </CardTitle>
          <CardDescription>
            Adicione URLs de sites para serem acessados automaticamente
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex gap-2">
            <Input
              placeholder="https://example.com"
              value={newSiteUrl}
              onChange={(e) => setNewSiteUrl(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleAddSite()}
              className="flex-1"
            />
            <Button onClick={handleAddSite}>
              <Plus size={16} className="mr-2" />
              Adicionar
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Sites List */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Globe size={20} />
            Sites Configurados ({sites.length})
          </CardTitle>
          <CardDescription>
            Gerencie os sites que serão acessados automaticamente
          </CardDescription>
        </CardHeader>
        <CardContent>
          {sites.length === 0 ? (
            <div className="text-center py-8">
              <Globe size={48} className="mx-auto text-slate-400 mb-4" />
              <p className="text-slate-600">Nenhum site configurado</p>
              <p className="text-sm text-slate-500">Adicione alguns sites para começar</p>
            </div>
          ) : (
            <ScrollArea className="h-96">
              <div className="space-y-3">
                {sites.map((site) => (
                  <div key={site.id} className="flex items-center gap-4 p-4 border rounded-lg hover:bg-slate-50 transition-colors">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <Globe size={16} className="text-slate-600" />
                        <p className="font-medium truncate">{site.url}</p>
                        <Badge variant={site.status === 'active' ? 'default' : 'secondary'}>
                          {site.status === 'active' ? 'Ativo' : 'Inativo'}
                        </Badge>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-slate-600">
                        <span>Último acesso: {site.lastAccessed}</span>
                        <span className="text-green-600">✓ {site.successCount} sucessos</span>
                        <span className="text-red-600">✗ {site.errorCount} erros</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleToggleStatus(site.id, site.url, site.status)}
                      >
                        {site.status === 'active' ? (
                          <><PowerOff size={14} className="mr-1" /> Desativar</>
                        ) : (
                          <><Power size={14} className="mr-1" /> Ativar</>
                        )}
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleRemoveSite(site.id, site.url)}
                      >
                        <Trash2 size={14} className="mr-1" />
                        Remover
                      </Button>
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

export default SiteManager;