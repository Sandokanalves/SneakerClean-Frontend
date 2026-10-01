<template>
  <div class="customers-layout">
    <section class="panel customer-form-panel">
      <div class="section-heading">
        <div>
          <h2>
            <UserRound :size="19" />
            {{ editingId ? "Editar cliente" : "Cadastrar cliente" }}
          </h2>
          <p>Dados de contato e endereço do cliente.</p>
        </div>
      </div>
      <form class="form" @submit.prevent="saveCustomer">
        <label class="input-group"
          ><span>Nome</span
          ><input v-model.trim="form.name" required maxlength="200"
        /></label>
        <label class="input-group"
          ><span>Telefone / WhatsApp</span
          ><input
            :value="form.phone"
            @input="form.phone = maskPhone($event.target.value)"
            type="tel"
            inputmode="numeric"
            autocomplete="tel"
            placeholder="(11) 99999-9999"
            required
            maxlength="15"
        /></label>
        <label class="input-group"
          ><span>Endereço</span
          ><input v-model.trim="form.street" maxlength="300"
        /></label>
        <div class="form-row">
          <label class="input-group"
            ><span>Bairro</span
            ><input v-model.trim="form.neighborhood" maxlength="150"
          /></label>
          <label class="input-group"
            ><span>Cidade</span><input v-model.trim="form.city" maxlength="150"
          /></label>
        </div>
        <label class="input-group"
          ><span>CEP</span
          ><input
            :value="form.zipCode"
            @input="form.zipCode = maskZipCode($event.target.value)"
            inputmode="numeric"
            autocomplete="postal-code"
            placeholder="00000-000"
            maxlength="9"
        /></label>
        <p v-if="errorMessage" class="inline-error">{{ errorMessage }}</p>
        <div class="form-actions">
          <button
            v-if="editingId"
            class="secondary-button"
            type="button"
            @click="resetForm"
          >
            Cancelar edição
          </button>
          <button class="primary-button" type="submit" :disabled="isSaving">
            {{
              isSaving
                ? "Salvando..."
                : editingId
                  ? "Salvar alterações"
                  : "Cadastrar cliente"
            }}
          </button>
        </div>
      </form>
    </section>

    <section class="panel customer-list-panel">
      <div class="section-heading list-heading">
        <div>
          <h2><UsersRound :size="19" /> Clientes</h2>
          <p>{{ totalCount }} cadastro(s)</p>
        </div>
        <button
          class="icon-button"
          title="Atualizar clientes"
          @click="fetchCustomers"
        >
          <RefreshCw :size="16" />
        </button>
      </div>
      <form class="search-form" @submit.prevent="searchCustomers">
        <label class="input-group"
          ><span>Buscar por nome ou telefone</span
          ><input v-model.trim="search" placeholder="Nome ou telefone"
        /></label>
        <button class="secondary-button" type="submit">
          <Search :size="16" /> Buscar
        </button>
      </form>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Cliente</th>
              <th>Telefone</th>
              <th>Localização</th>
              <th>Situação</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="isLoading">
              <td colspan="5" class="table-empty">Carregando clientes...</td>
            </tr>
            <tr v-else-if="customers.length === 0">
              <td colspan="5" class="table-empty">
                Nenhum cliente encontrado.
              </td>
            </tr>
            <tr v-for="customer in customers" :key="customer.id">
              <td>{{ customer.name }}</td>
              <td>{{ customer.phone }}</td>
              <td>
                {{
                  [customer.neighborhood, customer.city]
                    .filter(Boolean)
                    .join(", ") || "-"
                }}
              </td>
              <td>
                <span
                  class="active-badge"
                  :class="customer.isActive ? 'is-active' : 'is-inactive'"
                  >{{ customer.isActive ? "Ativo" : "Inativo" }}</span
                >
              </td>
              <td class="actions-cell">
                <button
                  class="icon-button"
                  title="Editar cliente"
                  @click="editCustomer(customer)"
                >
                  <Pencil :size="15" />
                </button>
                <button
                  v-if="customer.isActive"
                  class="icon-button danger"
                  title="Desativar cliente"
                  @click="deactivateCustomer(customer)"
                >
                  <UserX :size="15" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pagination">
        <span>Página {{ pageNumber }} de {{ totalPages || 1 }}</span>
        <div>
          <button
            class="secondary-button"
            :disabled="pageNumber <= 1 || isLoading"
            @click="changePage(-1)"
          >
            Anterior
          </button>
          <button
            class="secondary-button"
            :disabled="pageNumber >= totalPages || isLoading"
            @click="changePage(1)"
          >
            Próxima
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import {
  Pencil,
  RefreshCw,
  Search,
  UserRound,
  UsersRound,
  UserX,
} from "lucide-vue-next";
import api from "../services/api";

const emptyForm = () => ({
  name: "",
  phone: "",
  street: "",
  neighborhood: "",
  city: "",
  zipCode: "",
});
const customers = ref([]);
const form = ref(emptyForm());
const editingId = ref(null);
const search = ref("");
const pageNumber = ref(1);
const totalPages = ref(0);
const totalCount = ref(0);
const isLoading = ref(false);
const isSaving = ref(false);
const errorMessage = ref("");

const maskZipCode = (value) => {
  const digits = value.replace(/\D/g, "").slice(0, 8);
  return digits.length > 5
    ? `${digits.slice(0, 5)}-${digits.slice(5)}`
    : digits;
};

const maskPhone = (value) => {
  const digits = value.replace(/\D/g, "").slice(0, 11);
  if (digits.length < 3) return digits ? `(${digits}` : "";

  const areaCode = `(${digits.slice(0, 2)})`;
  const number = digits.slice(2);
  if (number.length <= 4) return `${areaCode} ${number}`;
  if (digits.length <= 10)
    return `${areaCode} ${number.slice(0, 4)}-${number.slice(4)}`;
  return `${areaCode} ${number.slice(0, 5)}-${number.slice(5)}`;
};

const fetchCustomers = async () => {
  isLoading.value = true;
  errorMessage.value = "";
  try {
    const { data } = await api.get("/customers", {
      params: {
        page: pageNumber.value,
        pageSize: 20,
        search: search.value || undefined,
      },
    });
    customers.value = data.items;
    totalPages.value = data.totalPages;
    totalCount.value = data.totalCount;
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível carregar os clientes.";
  } finally {
    isLoading.value = false;
  }
};

const searchCustomers = () => {
  pageNumber.value = 1;
  fetchCustomers();
};

const changePage = (offset) => {
  pageNumber.value += offset;
  fetchCustomers();
};

const resetForm = () => {
  editingId.value = null;
  form.value = emptyForm();
  errorMessage.value = "";
};

const editCustomer = (customer) => {
  editingId.value = customer.id;
  form.value = {
    name: customer.name,
    phone: maskPhone(customer.phone),
    street: customer.street || "",
    neighborhood: customer.neighborhood || "",
    city: customer.city || "",
    zipCode: maskZipCode(customer.zipCode || ""),
  };
  errorMessage.value = "";
  window.scrollTo({ top: 0, behavior: "smooth" });
};

const saveCustomer = async () => {
  isSaving.value = true;
  errorMessage.value = "";
  try {
    if (editingId.value)
      await api.put(`/customers/${editingId.value}`, form.value);
    else await api.post("/customers", form.value);
    resetForm();
    pageNumber.value = 1;
    await fetchCustomers();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível salvar o cliente.";
  } finally {
    isSaving.value = false;
  }
};

const deactivateCustomer = async (customer) => {
  if (!window.confirm(`Desativar o cliente ${customer.name}?`)) return;
  errorMessage.value = "";
  try {
    await api.delete(`/customers/${customer.id}`);
    await fetchCustomers();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message ||
      "Não foi possível desativar o cliente. Verifique sua permissão de administrador.";
  }
};

onMounted(fetchCustomers);
</script>

<style scoped>
.customers-layout {
  display: grid;
  grid-template-columns: minmax(280px, 0.72fr) minmax(0, 1.5fr);
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
.list-heading,
.form-row,
.form-actions,
.search-form,
.pagination {
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
.section-heading h2 svg {
  color: var(--accent-gold);
}
.section-heading p {
  margin-top: 4px;
  color: var(--text-muted);
  font-size: 12px;
}
.form-row > * {
  flex: 1;
}
.form-actions {
  align-items: stretch;
}
.primary-button,
.secondary-button,
.icon-button {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  gap: 7px;
}
.primary-button {
  flex: 1;
  padding: 11px;
  color: #101010;
  background: var(--accent-gold);
}
.secondary-button {
  padding: 9px 11px;
  color: #fff;
  background: #334155;
  white-space: nowrap;
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
.search-form {
  align-items: flex-end;
  margin-bottom: 14px;
}
.search-form .input-group {
  flex: 1;
}
.inline-error {
  margin: 10px 0;
  color: #fca5a5;
  font-size: 13px;
}
.table-wrap {
  width: 100%;
  overflow-x: auto;
}
table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}
th,
td {
  padding: 11px 9px;
  border-bottom: 1px solid var(--border-color);
}
th {
  color: var(--text-muted);
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}
td {
  color: #e2e8f0;
}
.table-empty {
  padding: 24px;
  color: var(--text-muted);
  text-align: center;
}
.actions-cell {
  display: flex;
  gap: 6px;
}
.active-badge {
  display: inline-block;
  padding: 4px 7px;
  border-radius: 4px;
  font-size: 11px;
}
.is-active {
  color: #6ee7b7;
  background: #064e3b;
}
.is-inactive {
  color: #cbd5e1;
  background: #334155;
}
.pagination {
  margin-top: 14px;
  color: var(--text-muted);
  font-size: 12px;
}
.pagination > div {
  display: flex;
  gap: 7px;
}
.pagination button {
  font-size: 12px;
}
@media (max-width: 980px) {
  .customers-layout {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 560px) {
  .panel {
    padding: 15px;
  }
  .form-row {
    align-items: stretch;
    flex-direction: column;
  }
  .search-form {
    align-items: stretch;
    flex-direction: column;
  }
  .form-actions {
    flex-direction: column-reverse;
  }
  .pagination {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
