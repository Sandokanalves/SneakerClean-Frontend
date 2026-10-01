<template>
  <div class="app-container">
    <!-- HEADER DA EMPRESA -->
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
          ><ShieldCheck :size="16" /> Modulo Administrativo</span
        >
        <button class="btn-logout" @click="handleLogout">
          <LogOut :size="16" /> Sair
        </button>
      </div>
    </header>

    <!-- TELA DE AUTH / LOGIN JWT -->
    <main v-if="!token" class="auth-wrapper">
      <div class="auth-card">
        <div class="auth-header">
          <Lock class="auth-icon" />
          <h2>Acesso Restrito</h2>
          <p>Entre com suas credenciais do painel corporativo</p>
        </div>

        <form @submit.prevent="handleLogin" class="form">
          <div class="input-group">
            <label>E-mail Corporativo</label>
            <input
              v-model="email"
              type="email"
              placeholder="admin@primeshoecare.com"
              required
            />
          </div>
          <div class="input-group">
            <label>Senha</label>
            <input
              v-model="password"
              type="password"
              placeholder="••••••••"
              required
            />
          </div>
          <button type="submit" class="btn-primary">
            Acessar Painel <ArrowRight :size="18" />
          </button>
        </form>
        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>
      </div>
    </main>

    <!-- PAINEL DASHBOARD DA PRIME SHOE CARE -->
    <main v-else class="dashboard">
      <!-- CARDS DE METRICAS (KPIs) -->
      <section class="kpi-grid">
        <div class="kpi-card gold">
          <div class="kpi-info">
            <span>Faturamento Total</span>
            <h3>R$ {{ totalRevenue.toFixed(2) }}</h3>
          </div>
          <DollarSign class="kpi-icon" />
        </div>
        <div class="kpi-card blue">
          <div class="kpi-info">
            <span>Ordens em Andamento</span>
            <h3>{{ orders.length }}</h3>
          </div>
          <PackageCheck class="kpi-icon" />
        </div>
        <div class="kpi-card green">
          <div class="kpi-info">
            <span>Satisfação Garantida</span>
            <h3>100% Premium</h3>
          </div>
          <Award class="kpi-icon" />
        </div>
      </section>

      <div class="content-grid">
        <!-- FORMULÁRIO DE NOVA ORDEM DE SERVIÇO -->
        <section class="card-form">
          <h2><PlusCircle :size="20" /> Nova Ordem de Serviço</h2>
          <form @submit.prevent="createOrder" class="form">
            <div class="form-row">
              <div class="input-group">
                <label>Nome do Cliente</label>
                <input
                  v-model="newOrder.customerName"
                  placeholder="Ex: Sandokan Oliveira"
                  required
                />
              </div>
              <div class="input-group">
                <label>Telefone / WhatsApp</label>
                <input
                  v-model="newOrder.customerPhone"
                  placeholder="(81) 99999-9999"
                  required
                />
              </div>
            </div>

            <div class="items-section">
              <h3><Footprints :size="18" /> Dados do Tênis</h3>
              <div class="form-row">
                <div class="input-group">
                  <label>Marca</label>
                  <input
                    v-model="newItem.sneakerBrand"
                    placeholder="Nike, Adidas, Jordan"
                    required
                  />
                </div>
                <div class="input-group">
                  <label>Modelo</label>
                  <input
                    v-model="newItem.sneakerModel"
                    placeholder="Air Force 1, Yeezy 350"
                    required
                  />
                </div>
                <div class="input-group short">
                  <label>Tamanho</label>
                  <input
                    v-model.number="newItem.size"
                    type="number"
                    placeholder="41"
                    required
                  />
                </div>
              </div>

              <div class="form-row">
                <div class="input-group">
                  <label>Serviço Desejado</label>
                  <select v-model="newItem.serviceDescription">
                    <option value="Higienização Completa + Impermeabilização">
                      Higienização Completa + Impermeabilização
                    </option>
                    <option value="Limpeza de Camurça / Detalhes Finos">
                      Limpeza de Camurça / Detalhes Finos
                    </option>
                    <option value="Restauração de Cor & Solado">
                      Restauração de Cor & Solado
                    </option>
                  </select>
                </div>
                <div class="input-group short">
                  <label>Valor (R$)</label>
                  <input
                    v-model.number="newItem.price"
                    type="number"
                    step="0.01"
                    required
                  />
                </div>
              </div>
            </div>

            <button type="submit" class="btn-primary gold-btn">
              Cadastrar Ordem de Serviço
            </button>
          </form>
        </section>

        <!-- LISTAGEM DE ORDENS DE SERVIÇO -->
        <section class="card-list">
          <div class="list-header">
            <h2><ListOrdered :size="20" /> Ordens Ativas</h2>
            <button class="btn-refresh" @click="fetchOrders">
              <RefreshCw :size="16" /> Atualizar
            </button>
          </div>

          <div class="order-list">
            <div v-if="orders.length === 0" class="empty-state">
              Nenhuma ordem cadastrada no momento.
            </div>

            <div v-for="order in orders" :key="order.id" class="order-card">
              <div class="order-card-header">
                <div>
                  <strong>{{ order.customerName }}</strong>
                  <span class="phone">{{ order.customerPhone }}</span>
                </div>
                <span class="status-badge">{{ order.status }}</span>
              </div>

              <div class="order-items">
                <div
                  v-for="(item, idx) in order.items"
                  :key="idx"
                  class="sneaker-detail"
                >
                  <Footprints :size="16" class="item-icon" />
                  <span
                    ><strong
                      >{{ item.sneakerBrand }} {{ item.sneakerModel }}</strong
                    >
                    (Tam: {{ item.size }}) - {{ item.serviceDescription }}</span
                  >
                </div>
              </div>

              <div class="order-footer">
                <span>Data: {{ formatDate(order.createdAt) }}</span>
                <strong class="price"
                  >R$ {{ order.totalAmount.toFixed(2) }}</strong
                >
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import {
  Sparkles,
  Lock,
  ArrowRight,
  ShieldCheck,
  LogOut,
  DollarSign,
  PackageCheck,
  Award,
  PlusCircle,
  Footprints,
  ListOrdered,
  RefreshCw,
} from "lucide-vue-next";
import api from "./services/api";

const token = ref(localStorage.getItem("prime_token") || "");
const email = ref("admin@primeshoecare.com");
const password = ref("123456");
const errorMessage = ref("");

const orders = ref([]);
const newOrder = ref({ customerName: "", customerPhone: "" });
const newItem = ref({
  sneakerBrand: "",
  sneakerModel: "",
  size: 41,
  serviceDescription: "Higienização Completa + Impermeabilização",
  price: 120.0,
});

const totalRevenue = computed(() => {
  return orders.value.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
});

const handleLogin = async () => {
  try {
    const response = await api.post("/auth/login", {
      email: email.value,
      password: password.value,
    });
    token.value = response.data.token;
    localStorage.setItem("prime_token", token.value);
    errorMessage.value = "";
    fetchOrders();
  } catch (err) {
    errorMessage.value = "Credenciais inválidas. Verifique seu e-mail e senha.";
  }
};

const handleLogout = () => {
  token.value = "";
  localStorage.removeItem("prime_token");
};

const fetchOrders = async () => {
  try {
    const response = await api.get("/orders");
    orders.value = response.data;
  } catch (err) {
    console.error("Erro ao buscar ordens:", err);
  }
};

const createOrder = async () => {
  try {
    const payload = {
      customerName: newOrder.value.customerName,
      customerPhone: newOrder.value.customerPhone,
      deliveryAddress: null,
      items: [newItem.value],
    };

    await api.post("/orders", payload);
    alert("Ordem de serviço cadastrada com sucesso na Prime Shoe Care!");
    newOrder.value = { customerName: "", customerPhone: "" };
    fetchOrders();
  } catch (err) {
    alert("Erro ao criar ordem de serviço.");
  }
};

const formatDate = (dateString) => {
  if (!dateString) return "";
  return new Date(dateString).toLocaleDateString("pt-BR");
};

onMounted(() => {
  if (token.value) {
    fetchOrders();
  }
});
</script>

<style scoped>
.app-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

/* HEADER */
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-color);
  margin-bottom: 30px;
}
.logo-container {
  display: flex;
  align-items: center;
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
  letter-spacing: 1px;
  color: #fff;
}
.tagline {
  font-size: 12px;
  color: var(--text-muted);
}
.user-info {
  display: flex;
  align-items: center;
  gap: 15px;
}
.user-badge {
  background: #1e293b;
  color: #38bdf8;
  border: 1px solid #0284c7;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 6px;
}
.btn-logout {
  background: #ef4444;
  color: white;
  padding: 8px 14px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
}

/* AUTH */
.auth-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 60px 0;
}
.auth-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  padding: 40px;
  border-radius: 16px;
  width: 100%;
  max-width: 420px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
}
.auth-header {
  text-align: center;
  margin-bottom: 25px;
}
.auth-icon {
  color: var(--accent-gold);
  width: 40px;
  height: 40px;
  margin-bottom: 10px;
}
.auth-header h2 {
  font-size: 20px;
  color: #fff;
}
.auth-header p {
  font-size: 13px;
  color: var(--text-muted);
  margin-top: 5px;
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
  width: 100%;
}
.input-group.short {
  width: 120px;
}
.input-group label {
  font-size: 12px;
  color: var(--text-muted);
  font-weight: 600;
}
input,
select {
  background: #0f172a;
  border: 1px solid var(--border-color);
  color: #fff;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
}
input:focus,
select:focus {
  border-color: var(--accent-blue);
}
.btn-primary {
  background: var(--accent-blue);
  color: white;
  padding: 12px;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  margin-top: 10px;
}
.error-msg {
  color: #f87171;
  font-size: 13px;
  text-align: center;
  margin-top: 15px;
}

/* KPI CARDS */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}
.kpi-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  padding: 20px;
  border-radius: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.kpi-card.gold {
  border-left: 4px solid var(--accent-gold);
}
.kpi-card.blue {
  border-left: 4px solid var(--accent-blue);
}
.kpi-card.green {
  border-left: 4px solid #10b981;
}
.kpi-info span {
  font-size: 12px;
  color: var(--text-muted);
}
.kpi-info h3 {
  font-size: 24px;
  color: #fff;
  margin-top: 5px;
}
.kpi-icon {
  width: 32px;
  height: 32px;
  opacity: 0.8;
}

/* CONTENT GRID */
.content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
}
@media (max-width: 900px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
}
.card-form,
.card-list {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  padding: 25px;
  border-radius: 16px;
}
.card-form h2,
.list-header h2 {
  font-size: 18px;
  color: #fff;
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
}
.form-row {
  display: flex;
  gap: 15px;
}
.items-section {
  background: #0f172a;
  padding: 15px;
  border-radius: 10px;
  border: 1px solid var(--border-color);
  margin: 10px 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.items-section h3 {
  font-size: 14px;
  color: var(--accent-gold);
  display: flex;
  align-items: center;
  gap: 6px;
}
.gold-btn {
  background: var(--accent-gold);
  color: #000;
  font-weight: 700;
}

/* LISTA DE PEDIDOS */
.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.btn-refresh {
  background: #334155;
  color: #fff;
  padding: 6px 12px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
}
.order-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
  max-height: 500px;
  overflow-y: auto;
  padding-right: 5px;
}
.empty-state {
  text-align: center;
  color: var(--text-muted);
  padding: 30px 0;
  font-size: 14px;
}
.order-card {
  background: #0f172a;
  border: 1px solid var(--border-color);
  border-radius: 10px;
  padding: 15px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.order-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}
.order-card-header strong {
  color: #fff;
  font-size: 15px;
}
.phone {
  display: block;
  font-size: 12px;
  color: var(--text-muted);
}
.status-badge {
  background: #0284c7;
  color: white;
  font-size: 11px;
  padding: 3px 8px;
  border-radius: 12px;
  font-weight: 600;
}
.sneaker-detail {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #cbd5e1;
}
.item-icon {
  color: var(--accent-gold);
}
.order-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid var(--border-color);
  pt: 8px;
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 5px;
}
.price {
  color: #10b981;
  font-size: 15px;
}
</style>
