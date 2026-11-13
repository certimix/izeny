import React, { useState } from 'react';
import { 
  ShieldCheck, 
  Users, 
  MessageSquare, 
  Building, 
  CheckCircle2, 
  ArrowRight, 
  LogIn, 
  UserPlus, 
  Share2, 
  Check, 
  Globe, 
  Layers, 
  Wrench, 
  Briefcase 
} from 'lucide-react';
import type { User } from '../types';

interface AboutViewProps {
  currentUser: User | null;
  onOpenAuth: () => void;
  onGoFeed: () => void;
}

export const AboutView: React.FC<AboutViewProps> = ({
  currentUser,
  onOpenAuth,
  onGoFeed,
}) => {
  const [copied, setCopied] = useState(false);

  const handleShare = () => {
    navigator.clipboard.writeText('https://izeny.zenydesk.com/');
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 text-slate-900 dark:text-slate-100 pb-16">
      {/* HERO SECTION */}
      <div className="px-6 py-10 md:py-14 border-b border-slate-200/80 dark:border-slate-800 bg-gradient-to-b from-blue-50/60 to-white dark:from-slate-950 dark:to-slate-900">
        <div className="max-w-xl mx-auto flex flex-col items-center text-center">
          {/* LOGO */}
          <div className="w-24 h-24 rounded-3xl bg-white p-3.5 shadow-md border border-slate-200/80 dark:border-slate-700 flex items-center justify-center mb-6">
            <img 
              src="/logo.png" 
              alt="iZeny Logomarca" 
              className="w-full h-full object-contain" 
            />
          </div>

          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-blue-100 dark:bg-blue-950/80 text-blue-700 dark:text-blue-300 text-xs font-bold mb-4">
            <Globe className="w-3.5 h-3.5" />
            <span>Rede Oficial do Ecossistema ZenyDesk</span>
          </div>

          <h1 className="text-3xl md:text-4xl font-black tracking-tight text-slate-900 dark:text-white leading-tight mb-4">
            Conexão, Suporte e Networking para Técnicos e Empresas
          </h1>

          <p className="text-sm md:text-base text-slate-600 dark:text-slate-300 leading-relaxed max-w-lg mb-8">
            O <strong>iZeny</strong> é o espaço exclusivo onde técnicos de bancada, assistências técnicas, empresas de automação e parceiros de TI trocam conhecimentos, resolvem dúvidas e expandem negócios em todo o Brasil.
          </p>

          {/* ACTION BUTTONS */}
          <div className="flex flex-wrap items-center justify-center gap-3 w-full">
            {!currentUser ? (
              <>
                <button
                  onClick={onOpenAuth}
                  className="px-6 py-3 rounded-full bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm shadow-md transition flex items-center gap-2 active:scale-95"
                >
                  <UserPlus className="w-4 h-4" />
                  <span>Criar Minha Conta Gratuita</span>
                </button>
                <button
                  onClick={onOpenAuth}
                  className="px-6 py-3 rounded-full border border-slate-300 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200 font-bold text-sm transition flex items-center gap-2"
                >
                  <LogIn className="w-4 h-4" />
                  <span>Entrar na Conta</span>
                </button>
              </>
            ) : (
              <>
                <button
                  onClick={onGoFeed}
                  className="px-6 py-3 rounded-full bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm shadow-md transition flex items-center gap-2 active:scale-95"
                >
                  <span>Ir para o Feed Principal</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
                <button
                  onClick={handleShare}
                  className="px-6 py-3 rounded-full border border-slate-300 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200 font-bold text-sm transition flex items-center gap-2"
                >
                  {copied ? (
                    <>
                      <Check className="w-4 h-4 text-emerald-500" />
                      <span className="text-emerald-600 dark:text-emerald-400">Link Copiado!</span>
                    </>
                  ) : (
                    <>
                      <Share2 className="w-4 h-4" />
                      <span>Compartilhar iZeny</span>
                    </>
                  )}
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {/* PILLARS / BENEFÍCIOS REAIS */}
      <div className="px-6 py-10 space-y-8 max-w-xl mx-auto">
        <div className="text-center">
          <h2 className="text-xl md:text-2xl font-black text-slate-900 dark:text-white tracking-tight">
            Por que fazer parte da Comunidade iZeny?
          </h2>
          <p className="text-xs md:text-sm text-slate-500 dark:text-slate-400 mt-1">
            Construído sob medida para a realidade prática de quem atua com tecnologia no Brasil.
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4">
          {/* PILAR 1 */}
          <div className="p-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40 flex items-start gap-4 transition hover:border-blue-400/50">
            <div className="w-10 h-10 rounded-xl bg-blue-100 dark:bg-blue-950 text-blue-600 dark:text-blue-400 flex items-center justify-center flex-shrink-0">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-sm text-slate-900 dark:text-white mb-1">
                Atendimento Especializado &amp; Suporte Técnico Direto
              </h3>
              <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                Interaja diretamente com a equipe ZenyDesk e técnicos experientes para esclarecer dúvidas sobre configurações, laudos técnicos no ZenyDesk O.S., rotinas fiscais no ZenyDesk ERP e conectividade no Acesso Remoto.
              </p>
            </div>
          </div>

          {/* PILAR 2 */}
          <div className="p-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40 flex items-start gap-4 transition hover:border-blue-400/50">
            <div className="w-10 h-10 rounded-xl bg-emerald-100 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 flex items-center justify-center flex-shrink-0">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-sm text-slate-900 dark:text-white mb-1">
                Networking Profissional &amp; Parcerias Regionais
              </h3>
              <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                Conecte-se com técnicos e oficinas em outras cidades e estados. Atenda clientes com filiais ou demandas externas através de parceiros locais verificados da comunidade.
              </p>
            </div>
          </div>

          {/* PILAR 3 */}
          <div className="p-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40 flex items-start gap-4 transition hover:border-blue-400/50">
            <div className="w-10 h-10 rounded-xl bg-amber-100 dark:bg-amber-950 text-amber-600 dark:text-amber-400 flex items-center justify-center flex-shrink-0">
              <Wrench className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-sm text-slate-900 dark:text-white mb-1">
                Bancada, Hardware &amp; Soluções Práticas
              </h3>
              <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                Compartilhamento diário de diagnósticos de placas, esquemas elétricos, impressoras térmicas de PDV, leitores seriais e recuperação de sistemas operacionais.
              </p>
            </div>
          </div>

          {/* PILAR 4 */}
          <div className="p-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40 flex items-start gap-4 transition hover:border-blue-400/50">
            <div className="w-10 h-10 rounded-xl bg-purple-100 dark:bg-purple-950 text-purple-600 dark:text-purple-400 flex items-center justify-center flex-shrink-0">
              <Layers className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-sm text-slate-900 dark:text-white mb-1">
                Integração Total com todo o Ecossistema
              </h3>
              <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                Ambiente unificado e conectado com o portal de Acesso Remoto (<a href="https://zenydesk.com" target="_blank" rel="noreferrer" className="text-blue-500 hover:underline">zenydesk.com</a>), Ordens de Serviço (<a href="https://os.zenydesk.com" target="_blank" rel="noreferrer" className="text-blue-500 hover:underline">os.zenydesk.com</a>) e Gestão Fiscal (<a href="https://erp.zenydesk.com" target="_blank" rel="noreferrer" className="text-blue-500 hover:underline">erp.zenydesk.com</a>).
              </p>
            </div>
          </div>
        </div>

        {/* BOTTOM CTA BANNER */}
        <div className="p-6 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-700 text-white text-center shadow-lg space-y-4">
          <h3 className="text-lg md:text-xl font-black">
            Pronto para impulsionar a sua atuação técnica?
          </h3>
          <p className="text-xs md:text-sm text-blue-100 max-w-md mx-auto">
            Cadastre-se gratuitamente em segundos com sua conta Google ou e-mail corporativo.
          </p>
          <div className="pt-2">
            {!currentUser ? (
              <button
                onClick={onOpenAuth}
                className="px-8 py-3 bg-white text-blue-700 hover:bg-blue-50 font-black text-sm rounded-full shadow-md transition active:scale-95"
              >
                Criar Minha Conta Gratuita Agora
              </button>
            ) : (
              <button
                onClick={onGoFeed}
                className="px-8 py-3 bg-white text-blue-700 hover:bg-blue-50 font-black text-sm rounded-full shadow-md transition active:scale-95"
              >
                Acessar o Feed da Comunidade
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
export default AboutView;
