<template>
  <div class="orders-layout">
    <section class="panel order-form-panel">
      <div class="section-heading">
        <div>
          <h2>
            <PlusCircle :size="19" />
            {{
              editingOrder
                ? `Editar ${editingOrder.orderCode}`
                : "Nova Ordem de Serviço"
            }}
          </h2>
          <p>
            {{
              editingOrder
                ? "Atualize os itens e o status da OS em andamento."
                : "Cadastre vários pares em uma única OS."
            }}
          </p>
        </div>
      </div>
      <form class="form" @submit.prevent="saveOrder">
        <label class="input-group">
          <span>Cliente</span>
          <select
            v-model="customerId"
            :disabled="Boolean(editingOrder)"
            required
          >
            <option value="" disabled>Selecione um cliente cadastrado</option>
            <option
              v-for="customer in customers"
              :key="customer.id"
              :value="customer.id"
            >
              {{ customer.name }} · {{ customer.phone }}
            </option>
          </select>
        </label>
        <label v-if="editingOrder" class="input-group">
          <span>Status da OS</span>
          <select v-model="editingOrder.status" required>
            <option
              v-for="status in statuses"
              :key="status.value"
              :value="status.value"
            >
              {{ status.label }}
            </option>
          </select>
        </label>

        <section
          v-for="(item, index) in items"
          :key="item.key"
          class="item-editor"
        >
          <div class="item-heading">
            <h3><Footprints :size="17" /> Tênis {{ index + 1 }}</h3>
            <button
              v-if="items.length > 1"
              class="icon-button danger"
              type="button"
              title="Remover tênis"
              @click="removeItem(index)"
            >
              <Trash2 :size="16" />
            </button>
          </div>
          <div class="item-fields">
            <label class="input-group"
              ><span>Marca</span
              ><input
                v-model.trim="item.sneakerBrand"
                placeholder="Nike, Adidas..."
                required
                maxlength="100"
            /></label>
            <label class="input-group"
              ><span>Modelo</span
              ><input
                v-model.trim="item.sneakerModel"
                placeholder="Air Force 1"
                required
                maxlength="150"
            /></label>
            <label class="input-group"
              ><span>Cor</span
              ><input
                v-model.trim="item.color"
                placeholder="Branco"
                maxlength="80"
            /></label>
            <label class="input-group"
              ><span>Tamanho</span
              ><input
                v-model.number="item.size"
                type="number"
                min="1"
                max="60"
                required
            /></label>
          </div>
          <div class="services-block">
            <div class="services-heading">
              <h4>Serviços deste tênis</h4>
              <button
                class="secondary-button"
                type="button"
                @click="addService(index)"
              >
                <Plus :size="15" /> Adicionar serviço
              </button>
            </div>
            <div
              v-for="(service, serviceIndex) in item.services"
              :key="service.key"
              class="service-editor"
            >
              <label class="input-group wide">
                <span>Serviço {{ serviceIndex + 1 }}</span>
                <select v-model="service.description" required>
                  <option>Higienização Prime</option>
                  <option>Desamarelamento</option>
                  <option>Reparo/Colagem</option>
                </select>
              </label>
              <label class="input-group">
                <span>Valor do serviço (R$)</span>
                <input
                  v-model.number="service.price"
                  type="number"
                  min="0.01"
                  step="0.01"
                  required
                />
              </label>
              <button
                v-if="item.services.length > 1"
                class="icon-button danger remove-service"
                type="button"
                title="Remover serviço"
                @click="removeService(index, serviceIndex)"
              >
                <Trash2 :size="15" />
              </button>
              <label class="input-group full">
                <span>Observações do serviço</span>
                <textarea
                  v-model.trim="service.notes"
                  rows="2"
                  maxlength="500"
                  placeholder="Detalhes adicionais do serviço"
                />
              </label>
            </div>
          </div>
        </section>

        <button
          class="secondary-button add-button"
          type="button"
          @click="addItem"
        >
          <Plus :size="16" /> Adicionar tênis
        </button>
        <div class="total-row">
          <span
            >Subtotal ({{ serviceCount }}
            {{ serviceCount === 1 ? "serviço" : "serviços" }})</span
          >
          <strong>{{ currency(subtotal) }}</strong>
        </div>
        <p v-if="errorMessage" class="inline-error">{{ errorMessage }}</p>
        <button
          v-if="editingOrder"
          class="secondary-button add-button"
          type="button"
          @click="cancelEdit"
        >
          Cancelar edição
        </button>
        <button
          class="primary-button"
          type="submit"
          :disabled="isSaving || customers.length === 0"
        >
          {{
            isSaving
              ? "Salvando..."
              : editingOrder
                ? "Salvar alterações da OS"
                : "Cadastrar ordem de serviço"
          }}
        </button>
      </form>
      <p v-if="customers.length === 0" class="hint">
        Cadastre um cliente antes de criar uma OS.
      </p>
    </section>

    <section class="panel order-list-panel">
      <div class="section-heading list-heading">
        <div>
          <h2><ClipboardList :size="19" /> Ordens de Serviço</h2>
          <p>{{ orders.length }} resultado(s)</p>
        </div>
        <button
          class="icon-button"
          title="Atualizar ordens"
          @click="fetchOrders"
        >
          <RefreshCw :size="16" />
        </button>
      </div>
      <div class="filters">
        <label class="input-group"
          ><span>Status</span>
          <select v-model="filters.status" @change="fetchOrders">
            <option value="">Todos os status</option>
            <option
              v-for="status in statuses"
              :key="status.value"
              :value="status.value"
            >
              {{ status.label }}
            </option>
          </select>
        </label>
        <label class="input-group"
          ><span>Mês</span>
          <select v-model="filters.month" @change="fetchOrders">
            <option value="">Todos os meses</option>
            <option
              v-for="month in months"
              :key="month.value"
              :value="month.value"
            >
              {{ month.label }}
            </option>
          </select>
        </label>
        <label class="input-group year-filter"
          ><span>Ano</span
          ><input
            v-model="filters.year"
            type="number"
            min="2000"
            max="2200"
            @change="fetchOrders"
        /></label>
      </div>

      <div class="order-list">
        <p v-if="isLoading" class="empty-state">Carregando ordens...</p>
        <p v-else-if="orders.length === 0" class="empty-state">
          Nenhuma ordem encontrada para esses filtros.
        </p>
        <article
          v-for="order in orders"
          :key="order.id"
          class="order-card"
          :class="{ 'print-target': printOrderId === order.id }"
        >
          <div class="order-card-header">
            <div>
              <strong>{{ order.orderCode }}</strong
              ><span>{{ order.customerName }} · {{ order.customerPhone }}</span>
            </div>
            <div class="order-card-tools">
              <span
                class="status-badge"
                :class="`status-${order.status.toLowerCase()}`"
                >{{ statusLabel(order.status) }}</span
              >
              <button
                v-if="order.status === 'InProgress'"
                class="icon-button"
                type="button"
                :title="`Editar ${order.orderCode}`"
                @click="startEdit(order)"
              >
                <Pencil :size="15" />
              </button>
              <button
                class="icon-button print-button"
                type="button"
                :title="`Imprimir ${order.orderCode} ou salvar em PDF`"
                @click="printOrder(order)"
              >
                <Printer :size="15" />
              </button>
            </div>
          </div>
          <div class="order-items">
            <div
              v-for="item in order.items"
              :key="item.id"
              class="sneaker-detail"
            >
              <Footprints :size="15" />
              <span
                ><strong
                  >{{ item.sneakerBrand }} {{ item.sneakerModel }}</strong
                >
                · {{ item.color || "Sem cor informada" }} · Tam.
                {{ item.size }} · {{ item.serviceDescription }}</span
              >
              <b>{{ currency(item.price) }}</b>
            </div>
          </div>
          <div class="order-footer">
            <span>{{ formatDate(order.createdAt) }}</span>
            <strong>{{ currency(order.totalAmount) }}</strong>
          </div>
          <label class="status-control"
            ><span>Atualizar status</span>
            <select
              :value="order.status"
              :aria-label="`Status de ${order.orderCode}`"
              :disabled="
                order.status === 'Cancelled' || order.status === 'Delivered'
              "
              @change="updateStatus(order, $event.target.value)"
            >
              <option
                v-for="status in statuses"
                :key="status.value"
                :value="status.value"
              >
                {{ status.label }}
              </option>
            </select>
          </label>
        </article>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, ref } from "vue";
import {
  ClipboardList,
  Footprints,
  Pencil,
  Plus,
  PlusCircle,
  Printer,
  RefreshCw,
  Trash2,
} from "lucide-vue-next";
import api from "../services/api";

const emit = defineEmits(["orders-changed"]);
const customers = ref([]);
const orders = ref([]);
const customerId = ref("");
const editingOrder = ref(null);
const itemKey = ref(0);
const items = ref([]);
const printOrderId = ref(null);
const isSaving = ref(false);
const isLoading = ref(false);
const errorMessage = ref("");
const now = new Date();
const filters = ref({
  status: "",
  month: "",
  year: "",
});
const statuses = [
  { value: "Open", label: "Aberta" },
  { value: "InProgress", label: "Em andamento" },
  { value: "Completed", label: "Concluída" },
  { value: "Cancelled", label: "Cancelada" },
  { value: "Delivered", label: "Entregue" },
];
const months = Array.from({ length: 12 }, (_, index) => ({
  value: index + 1,
  label: new Date(2000, index).toLocaleDateString("pt-BR", { month: "long" }),
}));
const subtotal = computed(() =>
  items.value.reduce(
    (sum, shoe) =>
      sum +
      shoe.services.reduce(
        (serviceSum, service) => serviceSum + (Number(service.price) || 0),
        0,
      ),
    0,
  ),
);
const serviceCount = computed(() =>
  items.value.reduce((count, shoe) => count + shoe.services.length, 0),
);
const serviceOptions = [
  "Higienização Prime",
  "Desamarelamento",
  "Reparo/Colagem",
];

function createService(
  description = serviceOptions[0],
  price = 120,
  notes = "",
) {
  return { key: itemKey.value++, description, price, notes };
}

function createItem() {
  return {
    key: itemKey.value++,
    sneakerBrand: "",
    sneakerModel: "",
    color: "",
    size: 41,
    services: [createService()],
  };
}

items.value = [createItem()];

const currency = (value) =>
  new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(
    Number(value || 0),
  );
const formatDate = (value) => new Date(value).toLocaleDateString("pt-BR");
const statusLabel = (value) =>
  statuses.find((status) => status.value === value)?.label || value;

const fetchCustomers = async () => {
  try {
    const { data } = await api.get("/customers/all");
    customers.value = data;
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível carregar os clientes.";
  }
};

const fetchOrders = async () => {
  isLoading.value = true;
  try {
    const params = {};
    if (filters.value.status) params.status = filters.value.status;
    if (filters.value.month) params.month = Number(filters.value.month);
    if (filters.value.year) params.year = Number(filters.value.year);
    const { data } = await api.get("/orders", { params });
    orders.value = data;
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível carregar as ordens.";
  } finally {
    isLoading.value = false;
  }
};

const addItem = () => items.value.push(createItem());
const removeItem = (index) => items.value.splice(index, 1);
const addService = (shoeIndex) =>
  items.value[shoeIndex].services.push(createService());
const removeService = (shoeIndex, serviceIndex) =>
  items.value[shoeIndex].services.splice(serviceIndex, 1);

function groupOrderItems(orderItems) {
  const shoes = new Map();
  for (const orderItem of orderItems) {
    const key = JSON.stringify([
      orderItem.sneakerBrand,
      orderItem.sneakerModel,
      orderItem.color,
      orderItem.size,
    ]);
    let shoe = shoes.get(key);
    if (!shoe) {
      shoe = {
        key: itemKey.value++,
        sneakerBrand: orderItem.sneakerBrand,
        sneakerModel: orderItem.sneakerModel,
        color: orderItem.color || "",
        size: orderItem.size,
        services: [],
      };
      shoes.set(key, shoe);
    }
    shoe.services.push(
      createService(
        orderItem.serviceDescription,
        orderItem.price,
        orderItem.notes || "",
      ),
    );
  }
  return [...shoes.values()];
}

const startEdit = async (order) => {
  errorMessage.value = "";
  try {
    const { data } = await api.get(`/orders/${order.id}`);
    editingOrder.value = data;
    customerId.value = data.customerId;
    items.value = groupOrderItems(data.items);
    window.scrollTo({ top: 0, behavior: "smooth" });
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      "Não foi possível carregar a OS para edição.";
  }
};

const cancelEdit = () => {
  editingOrder.value = null;
  customerId.value = "";
  items.value = [createItem()];
  errorMessage.value = "";
};

const saveOrder = async () => {
  errorMessage.value = "";
  isSaving.value = true;
  const payload = {
    customerId: customerId.value,
    deliveryAddress: null,
    items: items.value.flatMap((shoe) =>
      shoe.services.map((service) => ({
        sneakerBrand: shoe.sneakerBrand,
        sneakerModel: shoe.sneakerModel,
        color: shoe.color,
        size: shoe.size,
        serviceDescription: service.description,
        price: Number(service.price),
        notes: service.notes || null,
      })),
    ),
  };

  try {
    if (editingOrder.value) {
      await api.put(`/orders/${editingOrder.value.id}`, {
        status: editingOrder.value.status,
        items: payload.items,
      });
      cancelEdit();
    } else {
      await api.post("/orders", payload);
      customerId.value = "";
      items.value = [createItem()];
    }
    await fetchOrders();
    emit("orders-changed");
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível cadastrar a ordem.";
  } finally {
    isSaving.value = false;
  }
};

const updateStatus = async (order, status) => {
  try {
    await api.patch(`/orders/${order.id}/status`, { status });
    await fetchOrders();
    emit("orders-changed");
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível atualizar o status.";
    await fetchOrders();
  }
};

const printOrder = async (order) => {
  printOrderId.value = order.id;
  await nextTick();
  window.onafterprint = () => {
    printOrderId.value = null;
    window.onafterprint = null;
  };
  window.print();
};

onMounted(() => {
  fetchCustomers();
  fetchOrders();
});
</script>

<style scoped>
.orders-layout {
  display: grid;
  grid-template-columns: minmax(340px, 0.9fr) minmax(0, 1.1fr);
  gap: 18px;
  align-items: start;
}
.panel {
  min-width: 0;
  padding: 20px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: 8px;
}
.section-heading,
.item-heading,
.order-card-header,
.order-footer,
.total-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}
.section-heading {
  margin-bottom: 18px;
}
.section-heading h2 {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
}
.section-heading h2 svg,
.item-heading svg {
  color: var(--accent-gold);
}
.section-heading p,
.order-card-header span,
.order-footer,
.status-control span {
  margin-top: 4px;
  color: var(--text-muted);
  font-size: 12px;
}
.item-editor {
  padding: 14px;
  background: #0f172a;
  border: 1px solid var(--border-color);
  border-radius: 7px;
}
.item-heading {
  margin-bottom: 12px;
}
.item-heading h3 {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 14px;
}
.item-fields {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}
.item-fields .wide {
  grid-column: span 2;
}
.item-fields .full {
  grid-column: 1 / -1;
}
.secondary-button,
.primary-button,
.icon-button {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  gap: 7px;
}
.secondary-button {
  padding: 9px 11px;
  color: #fff;
  background: #334155;
}
.add-button {
  width: 100%;
}
.primary-button {
  width: 100%;
  padding: 12px;
  color: #101010;
  background: var(--accent-gold);
}
.icon-button {
  width: 34px;
  height: 34px;
  color: #fff;
  background: #334155;
}
.icon-button.danger {
  color: #fca5a5;
  background: #3b2024;
}
.total-row {
  padding: 13px 0;
  border-top: 1px solid var(--border-color);
  color: var(--text-muted);
  font-size: 14px;
}
.total-row strong {
  color: #fff;
  font-size: 19px;
}
.inline-error {
  color: #fca5a5;
  font-size: 13px;
}
.hint {
  margin-top: 12px;
  color: var(--text-muted);
  font-size: 12px;
}
.list-heading {
  margin-bottom: 14px;
}
.filters {
  display: grid;
  grid-template-columns: 1fr 1fr 90px;
  gap: 10px;
  padding-bottom: 15px;
  border-bottom: 1px solid var(--border-color);
}
.filters .input-group span {
  font-size: 11px;
}
.order-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-height: 720px;
  padding-top: 14px;
  overflow-y: auto;
}
.empty-state {
  padding: 25px 0;
  color: var(--text-muted);
  text-align: center;
  font-size: 13px;
}
.order-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px;
  background: #0f172a;
  border: 1px solid var(--border-color);
  border-radius: 7px;
}
.order-card-tools {
  display: flex;
  align-items: center;
  gap: 7px;
}
.order-card-header {
  align-items: flex-start;
}
.order-card-header strong {
  color: #fff;
  font-size: 14px;
}
.order-card-header span {
  display: block;
}
.status-badge {
  flex: 0 0 auto;
  padding: 4px 8px;
  border-radius: 5px;
  color: #fff !important;
  font-weight: 600;
}
.status-open {
  background: #0369a1;
}
.status-inprogress {
  background: #a16207;
}
.status-completed {
  background: #047857;
}
.status-cancelled {
  background: #991b1b;
}
.status-delivered {
  background: #166534;
}
.order-items {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.sneaker-detail {
  display: grid;
  grid-template-columns: 16px minmax(0, 1fr) auto;
  align-items: center;
  gap: 7px;
  color: #cbd5e1;
  font-size: 12px;
}
.sneaker-detail svg {
  color: var(--accent-gold);
}
.sneaker-detail b {
  white-space: nowrap;
}
.order-footer {
  padding-top: 10px;
  border-top: 1px solid var(--border-color);
}
.order-footer strong {
  color: #34d399;
  font-size: 14px;
}
.status-control {
  display: flex;
  align-items: center;
  gap: 10px;
}
.status-control span {
  margin: 0;
  white-space: nowrap;
}
.status-control select {
  max-width: 190px;
  padding: 7px 9px;
  font-size: 12px;
}
@page {
  size: A4;
  margin: 15mm;
}
@media print {
  :global(body) {
    color: #111 !important;
    background: #fff !important;
  }
  :global(.header),
  :global(.kpi-grid),
  :global(.module-tabs),
  :global(.error-banner),
  .order-form-panel,
  .list-heading,
  .filters,
  .status-control {
    display: none !important;
  }
  .orders-layout {
    display: block !important;
  }
  .order-list-panel {
    position: absolute !important;
    inset: 0 auto auto 0;
    width: 100%;
    padding: 0;
    color: #111 !important;
    background: #fff !important;
    border: 0;
  }
  .order-list {
    max-height: none;
    padding: 0;
    overflow: visible;
  }
  .order-card:not(.print-target) {
    display: none !important;
  }
  .print-target {
    display: flex !important;
    width: 100%;
    color: #111 !important;
    background: #fff !important;
    border: 1px solid #bbb;
    border-radius: 0;
    break-inside: avoid;
  }
  .print-target strong,
  .print-target span,
  .print-target b {
    color: #111 !important;
  }
  .print-target .order-items,
  .print-target .order-footer {
    border-color: #ccc;
  }
  .print-target .order-card-tools button {
    display: none !important;
  }
}
@media (max-width: 1000px) {
  .orders-layout {
    grid-template-columns: 1fr;
  }
  .order-list {
    max-height: none;
  }
}
@media (max-width: 520px) {
  .panel {
    padding: 15px;
  }
  .filters {
    grid-template-columns: 1fr 1fr;
  }
  .year-filter {
    grid-column: 1 / -1;
  }
  .item-fields {
    grid-template-columns: 1fr;
  }
  .item-fields .wide,
  .item-fields .full {
    grid-column: auto;
  }
  .status-control {
    align-items: flex-start;
    flex-direction: column;
  }
  .status-control select {
    max-width: none;
  }
}
</style>
