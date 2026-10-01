<template>
  <div class="app-container">
    <header class="header">
      <div class="logo-container">
        <Sparkles class="logo-icon" />
        <div>
          <h1>PRIME SHOE CARE</h1>
          <span class="tagline"
            >Higienização & Restauração Premium de Tênis</span
          >
        </div>
      </div>
      <div v-if="token" class="user-info">
        <span class="user-badge"
          ><ShieldCheck :size="16" /> Módulo Administrativo</span
        >
        <button class="btn-logout" @click="handleLogout">
          <LogOut :size="16" /> Sair
        </button>
      </div>
    </header>

    <main v-if="!token" class="auth-wrapper">
      <section class="auth-card">
        <div class="auth-header">
          <Lock class="auth-icon" />
          <h2>Acesso Restrito</h2>
          <p>Entre com suas credenciais do painel corporativo</p>
        </div>
        <form class="form" @submit.prevent="handleLogin">
          <label class="input-group">
            <span>E-mail Corporativo</span>
            <input
              v-model.trim="email"
              type="email"
              autocomplete="username"
              required
            />
          </label>
          <label class="input-group">
            <span>Senha</span>
            <div class="password-control">
              <input
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="current-password"
                required
              />
              <button
                class="password-toggle"
                type="button"
                :aria-label="showPassword ? 'Ocultar senha' : 'Mostrar senha'"
                :title="showPassword ? 'Ocultar senha' : 'Mostrar senha'"
                @click="showPassword = !showPassword"
              >
                <EyeOff v-if="showPassword" :size="18" />
                <Eye v-else :size="18" />
              </button>
            </div>
          </label>
          <button class="btn-primary" type="submit" :disabled="isLoggingIn">
            {{ isLoggingIn ? "Entrando..." : "Acessar Painel" }}
            <ArrowRight :size="18" />
          </button>
        </form>
        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>
      </section>
    </main>

    <main v-else class="dashboard">
      <p v-if="errorMessage" class="error-banner">{{ errorMessage }}</p>
      <section class="kpi-grid" aria-label="Métricas do mês">
        <article class="kpi-card gold">
          <div class="kpi-info">
            <span>Faturamento do mês</span>
            <h3>{{ currency(metrics.totalRevenueMonth) }}</h3>
          </div>
          <DollarSign class="kpi-icon" />
        </article>
        <article class="kpi-card blue">
          <div class="kpi-info">
            <span>OS abertas</span>
            <h3>{{ metrics.openOrdersCount }}</h3>
          </div>
          <PackageCheck class="kpi-icon" />
        </article>
        <article class="kpi-card green">
          <div class="kpi-info">
            <span>OS concluídas no mês</span>
            <h3>{{ metrics.completedOrdersMonthCount }}</h3>
          </div>
          <Award class="kpi-icon" />
        </article>
      </section>

      <nav class="module-tabs" aria-label="Módulos">
        <button
          :class="{ active: activeView === 'orders' }"
          @click="activeView = 'orders'"
        >
          <ClipboardList :size="17" /> Ordens de Serviço
        </button>
        <button
          :class="{ active: activeView === 'customers' }"
          @click="activeView = 'customers'"
        >
          <UsersRound :size="17" /> Clientes
        </button>
        <button
          v-if="userRole === 'Admin'"
          :class="{ active: activeView === 'users' }"
          @click="activeView = 'users'"
        >
          <UserPlus :size="17" /> Usuários
        </button>
        <button
          class="refresh-metrics"
          title="Atualizar métricas"
          @click="fetchMetrics"
        >
          <RefreshCw :size="16" />
        </button>
      </nav>

      <OrdersView
        v-if="activeView === 'orders'"
        @orders-changed="fetchMetrics"
      />
      <CustomersView v-else-if="activeView === 'customers'" />
      <UsersView v-else-if="activeView === 'users' && userRole === 'Admin'" />
    </main>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import {
  ArrowRight,
  Award,
  ClipboardList,
  DollarSign,
  Eye,
  EyeOff,
  Lock,
  LogOut,
  PackageCheck,
  RefreshCw,
  ShieldCheck,
  Sparkles,
  UserPlus,
  UsersRound,
} from "lucide-vue-next";
import CustomersView from "./components/CustomersView.vue";
import OrdersView from "./components/OrdersView.vue";
import UsersView from "./components/UsersView.vue";
import api from "./services/api";

const savedToken = localStorage.getItem("prime_token") || "";
const token = ref(savedToken);
const userRole = ref(
  localStorage.getItem("prime_role") || getTokenRole(savedToken),
);
const email = ref("admin@primeshoecare.com");
const password = ref("");
const showPassword = ref(false);
const errorMessage = ref("");
const isLoggingIn = ref(false);
const activeView = ref("orders");
const metrics = ref({
  totalRevenueMonth: 0,
  openOrdersCount: 0,
  completedOrdersMonthCount: 0,
});

const currency = (value) =>
  new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(
    Number(value || 0),
  );

const fetchMetrics = async () => {
  try {
    const { data } = await api.get("/dashboard/metrics");
    metrics.value = data;
    errorMessage.value = "";
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      "Não foi possível carregar as métricas.",
    );
  }
};

const handleLogin = async () => {
  isLoggingIn.value = true;
  try {
    const { data } = await api.post("/auth/login", {
      email: email.value,
      password: password.value,
    });
    token.value = data.token;
    userRole.value = data.user.role;
    localStorage.setItem("prime_token", token.value);
    localStorage.setItem("prime_role", userRole.value);
    localStorage.setItem("prime_user_id", data.user.id);
    errorMessage.value = "";
    await fetchMetrics();
  } catch (error) {
    errorMessage.value = getErrorMessage(
      error,
      "Credenciais inválidas. Verifique seu e-mail e senha.",
    );
  } finally {
    isLoggingIn.value = false;
  }
};

const handleLogout = () => {
  token.value = "";
  password.value = "";
  localStorage.removeItem("prime_token");
  localStorage.removeItem("prime_role");
  localStorage.removeItem("prime_user_id");
};

function getErrorMessage(error, fallback) {
  return error.response?.data?.message || fallback;
}

function getTokenRole(value) {
  try {
    const encodedClaims = value
      .split(".")[1]
      .replace(/-/g, "+")
      .replace(/_/g, "/");
    const claims = JSON.parse(
      atob(encodedClaims.padEnd(Math.ceil(encodedClaims.length / 4) * 4, "=")),
    );
    const roleClaim = Object.keys(claims).find(
      (key) => key === "role" || key.endsWith("/role"),
    );
    return claims[roleClaim] || "";
  } catch {
    return "";
  }
}

onMounted(() => {
  if (token.value) fetchMetrics();
});
</script>

<style>
.app-container {
  max-width: 1320px;
  margin: 0 auto;
  padding: 24px;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-color);
  margin-bottom: 26px;
}
.logo-container,
.user-info,
.user-badge,
.btn-logout,
.module-tabs,
.module-tabs button {
  display: flex;
  align-items: center;
}
.logo-container {
  gap: 12px;
}
.logo-icon {
  color: var(--accent-gold);
  width: 36px;
  height: 36px;
}
.header h1 {
  font-size: 24px;
  font-weight: 800;
  color: #fff;
}
.tagline {
  font-size: 12px;
  color: var(--text-muted);
}
.user-info {
  gap: 14px;
}
.user-badge {
  gap: 6px;
  padding: 6px 10px;
  color: #38bdf8;
  font-size: 12px;
}
.btn-logout {
  gap: 7px;
  padding: 9px 12px;
  color: white;
  background: #b93838;
}
.auth-wrapper {
  display: flex;
  justify-content: center;
  padding: 56px 0;
}
.auth-card {
  width: 100%;
  max-width: 420px;
  padding: 34px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: 12px;
}
.auth-header {
  text-align: center;
  margin-bottom: 24px;
}
.auth-icon {
  width: 38px;
  height: 38px;
  margin-bottom: 10px;
  color: var(--accent-gold);
}
.auth-header h2 {
  font-size: 20px;
}
.auth-header p {
  margin-top: 6px;
  color: var(--text-muted);
  font-size: 13px;
}
.form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}
.input-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}
.input-group span {
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 600;
}
.password-control {
  position: relative;
}
.password-control input {
  padding-right: 44px;
}
.password-toggle {
  position: absolute;
  top: 50%;
  right: 8px;
  display: grid;
  width: 30px;
  height: 30px;
  place-items: center;
  color: var(--text-muted);
  background: transparent;
  transform: translateY(-50%);
}
.password-toggle:hover {
  color: #fff;
}
input,
select,
textarea {
  width: 100%;
  min-width: 0;
  padding: 10px 12px;
  color: #fff;
  background: #0f172a;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  font: inherit;
  font-size: 14px;
}
input:focus,
select:focus,
textarea:focus {
  border-color: var(--accent-blue);
  outline: 2px solid transparent;
}
textarea {
  resize: vertical;
}
button {
  cursor: pointer;
  border: 0;
  border-radius: 6px;
  font: inherit;
  font-weight: 600;
  transition:
    background-color 0.18s ease,
    border-color 0.18s ease;
}
button:disabled {
  cursor: wait;
  opacity: 0.65;
}
.btn-primary {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
  padding: 12px;
  color: #fff;
  background: var(--accent-blue);
}
.error-msg,
.error-banner {
  color: #fca5a5;
  font-size: 13px;
}
.error-msg {
  margin-top: 14px;
  text-align: center;
}
.error-banner {
  margin-bottom: 14px;
  padding: 10px 12px;
  border: 1px solid #7f1d1d;
  border-radius: 6px;
  background: #351719;
}
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin-bottom: 24px;
}
.kpi-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-height: 102px;
  padding: 18px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-left: 4px solid;
  border-radius: 8px;
}
.kpi-card.gold {
  border-left-color: var(--accent-gold);
}
.kpi-card.blue {
  border-left-color: var(--accent-blue);
}
.kpi-card.green {
  border-left-color: #10b981;
}
.kpi-info span {
  color: var(--text-muted);
  font-size: 12px;
}
.kpi-info h3 {
  margin-top: 7px;
  color: #fff;
  font-size: 22px;
}
.kpi-icon {
  width: 28px;
  height: 28px;
  opacity: 0.8;
}
.module-tabs {
  gap: 6px;
  margin-bottom: 20px;
  border-bottom: 1px solid var(--border-color);
}
.module-tabs button {
  gap: 8px;
  padding: 11px 14px;
  color: var(--text-muted);
  background: transparent;
  border-bottom: 2px solid transparent;
  border-radius: 0;
}
.module-tabs button.active {
  color: #fff;
  border-bottom-color: var(--accent-gold);
}
.module-tabs .refresh-metrics {
  margin-left: auto;
  padding: 9px;
  border: 1px solid var(--border-color);
  border-radius: 6px;
}
@media (max-width: 700px) {
  .app-container {
    padding: 16px;
  }
  .header {
    align-items: flex-start;
    flex-direction: column;
  }
  .user-info {
    width: 100%;
    justify-content: space-between;
  }
  .kpi-grid {
    grid-template-columns: 1fr;
  }
  .kpi-card {
    min-height: 82px;
  }
  .module-tabs button {
    padding: 10px 8px;
    font-size: 13px;
  }
}
</style>
