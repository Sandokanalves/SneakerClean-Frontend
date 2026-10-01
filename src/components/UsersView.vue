<template>
  <div class="users-layout">
    <section class="panel user-form-panel">
      <div class="section-heading">
        <div>
          <h2>
            <UserRoundPlus :size="19" />
            {{ editingId ? "Editar usuário" : "Cadastrar usuário" }}
          </h2>
          <p>
            {{
              editingId
                ? "Atualize os dados e o perfil do usuário."
                : "Crie acessos administrativos ou de operador."
            }}
          </p>
        </div>
      </div>
      <form class="form" @submit.prevent="saveUser">
        <label class="input-group">
          <span>Nome</span>
          <input
            v-model.trim="form.name"
            required
            maxlength="150"
            autocomplete="name"
          />
        </label>
        <label class="input-group">
          <span>E-mail</span>
          <input
            v-model.trim="form.email"
            type="email"
            required
            maxlength="200"
            autocomplete="email"
          />
        </label>
        <label class="input-group">
          <span
            >Senha
            {{
              editingId
                ? "(deixe em branco para manter)"
                : "(mínimo 6 caracteres)"
            }}</span
          >
          <input
            v-if="!editingId"
            v-model="form.password"
            type="password"
            required
            minlength="6"
            autocomplete="new-password"
          />
        </label>
        <label class="input-group">
          <span>Perfil</span>
          <select v-model="form.role" required>
            <option value="Operador">Operador</option>
            <option value="Admin">Admin</option>
          </select>
        </label>
        <p v-if="errorMessage" class="inline-error">{{ errorMessage }}</p>
        <p v-if="successMessage" class="success-message">
          {{ successMessage }}
        </p>
        <div class="form-actions">
          <button
            v-if="editingId"
            class="secondary-button"
            type="button"
            @click="cancelEdit"
          >
            Cancelar
          </button>
          <button class="primary-button" type="submit" :disabled="isSaving">
            {{
              isSaving
                ? "Salvando..."
                : editingId
                  ? "Salvar alterações"
                  : "Cadastrar usuário"
            }}
          </button>
        </div>
      </form>
    </section>

    <section class="panel user-list-panel">
      <div class="section-heading">
        <div>
          <h2><UsersRound :size="19" /> Usuários cadastrados</h2>
          <p>{{ users.length }} usuário(s)</p>
        </div>
        <button
          class="icon-button"
          title="Atualizar usuários"
          @click="fetchUsers"
        >
          <RefreshCw :size="16" />
        </button>
      </div>
      <p v-if="listError" class="inline-error">{{ listError }}</p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Nome</th>
              <th>E-mail</th>
              <th>Perfil</th>
              <th>Situação</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="isLoading">
              <td colspan="5" class="table-empty">Carregando usuários...</td>
            </tr>
            <tr v-else-if="users.length === 0">
              <td colspan="5" class="table-empty">
                Nenhum usuário cadastrado.
              </td>
            </tr>
            <tr v-for="user in users" :key="user.id">
              <td>{{ user.name }}</td>
              <td>{{ user.email }}</td>
              <td>{{ user.role }}</td>
              <td>
                <span
                  class="active-badge"
                  :class="user.isActive ? 'is-active' : 'is-inactive'"
                  >{{ user.isActive ? "Ativo" : "Inativo" }}</span
                >
              </td>
              <td class="actions-cell">
                <button
                  class="icon-button"
                  type="button"
                  title="Editar usuário"
                  @click="editUser(user)"
                >
                  <Pencil :size="15" />
                </button>
                <button
                  v-if="user.isActive && user.id !== currentUserId"
                  class="icon-button danger"
                  type="button"
                  title="Desativar usuário"
                  @click="deactivateUser(user)"
                >
                  <UserX :size="15" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import {
  Pencil,
  RefreshCw,
  UserRoundPlus,
  UsersRound,
  UserX,
} from "lucide-vue-next";
import api from "../services/api";

const emptyForm = () => ({
  name: "",
  email: "",
  password: "",
  role: "Operador",
});
const form = ref(emptyForm());
const users = ref([]);
const editingId = ref(null);
const currentUserId = localStorage.getItem("prime_user_id") || "";
const isSaving = ref(false);
const isLoading = ref(false);
const errorMessage = ref("");
const listError = ref("");
const successMessage = ref("");

const fetchUsers = async () => {
  isLoading.value = true;
  listError.value = "";
  try {
    const { data } = await api.get("/users");
    users.value = data;
  } catch (error) {
    listError.value =
      error.response?.data?.message || "Não foi possível carregar os usuários.";
  } finally {
    isLoading.value = false;
  }
};

const cancelEdit = () => {
  editingId.value = null;
  form.value = emptyForm();
  errorMessage.value = "";
  successMessage.value = "";
};

const editUser = (user) => {
  editingId.value = user.id;
  form.value = {
    name: user.name,
    email: user.email,
    password: "",
    role: user.role,
  };
  errorMessage.value = "";
  successMessage.value = "";
  window.scrollTo({ top: 0, behavior: "smooth" });
};

const saveUser = async () => {
  isSaving.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    if (editingId.value) {
      await api.put(`/users/${editingId.value}`, {
        name: form.value.name,
        email: form.value.email,
        role: form.value.role,
      });
      cancelEdit();
      successMessage.value = "Usuário atualizado com sucesso.";
    } else {
      await api.post("/users", form.value);
      form.value = emptyForm();
      successMessage.value = "Usuário cadastrado com sucesso.";
    }
    await fetchUsers();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível cadastrar o usuário.";
  } finally {
    isSaving.value = false;
  }
};

const deactivateUser = async (user) => {
  if (!window.confirm(`Desativar o acesso de ${user.name}?`)) return;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    await api.delete(`/users/${user.id}`);
    if (editingId.value === user.id) cancelEdit();
    successMessage.value = "Usuário desativado com sucesso.";
    await fetchUsers();
  } catch (error) {
    errorMessage.value =
      error.response?.data?.message || "Não foi possível desativar o usuário.";
  }
};

onMounted(fetchUsers);
</script>

<style scoped>
.users-layout {
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
.section-heading {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
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
.form-actions {
  display: flex;
  align-items: stretch;
  gap: 8px;
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
.inline-error {
  color: #fca5a5;
  font-size: 13px;
}
.success-message {
  color: #6ee7b7;
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
.actions-cell {
  display: flex;
  gap: 6px;
}
.table-empty {
  padding: 24px;
  color: var(--text-muted);
  text-align: center;
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
@media (max-width: 980px) {
  .users-layout {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 560px) {
  .panel {
    padding: 15px;
  }
}
</style>
