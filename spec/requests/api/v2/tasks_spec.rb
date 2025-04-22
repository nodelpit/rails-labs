require 'rails_helper'

RSpec.describe "Api::V1::Bases", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { JwtService.encode({ user_id: user.id }) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  # Créer plusieurs tâches pour l'utilisateur principal et un autre utilisateur
  let!(:user_task1) { create(:task, user: user, title: "Tâche 1", description: "Description 1") }
  let!(:user_task2) { create(:task, user: user, title: "Tâche 2", description: "Description 2") }
  let!(:other_user_task) { create(:task, user: other_user, title: "Tâche d'un autre utilisateur") }

  describe "GET api_v2_tasks" do
    it "retourne toutes les tâches de l'utilisateur courant" do
      get api_v2_tasks_path, headers: headers
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)

      expect(json_response.size).to eq(2)
      expect(json_response.map { |t| t["id"] }).to include(user_task1.id, user_task2.id)
      expect(json_response.map { |t| t["id"] }).not_to include(other_user_task.id)
    end
  end

  describe "GET api_v2_task / id" do
    it "retourne la tâche demandée si elle appartient à l'utilisateur" do
      get api_v2_task_path(user_task1), headers: headers
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)

      expect(json_response["id"]).to eq(user_task1.id)
      expect(json_response["title"]).to eq("Tâche 1")
    end

    it "retourne une erreur pour une tâche inexistante" do
      get api_v2_task_path(999999), headers: headers

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)

      expect(json_response["error"]).to eq("Tâche non trouvée")
    end

    it "retourne une erreur pour une tâche appartenant à un autre utilisateur" do
      get api_v2_task_path(other_user_task), headers: headers

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)

      expect(json_response["error"]).to eq("Tâche non trouvée")
    end
  end

  describe "POST new_api_v2_task" do
    let(:valid_task_params) { { task: { title: "Nouvelle tâche", description: "Description" } } }
    let(:invalid_task_params) { { task: { title: "", description: "Description" } } }

    it "crée une nouvelle tâche avec des paramètres valides" do
      expect {
        post api_v2_tasks_path, params: valid_task_params, headers: headers
      }.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)

      expect(json_response["title"]).to eq("Nouvelle tâche")
      expect(json_response["user_id"]).to eq(user.id)
    end

    it "retourne des erreurs pour des paramètres invalides" do
      expect {
        post api_v2_tasks_path, params: invalid_task_params, headers: headers
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key("errors")
    end
  end

  describe "PATCH api_v2_task_path" do
    let(:update_params) { { task: { title: "Titre mis à jour" } } }
    let(:invalid_update_params) { { task: { title: "" } } }

    it "met à jour une tâche avec des paramètres valides" do
      patch api_v2_task_path(user_task1), params: update_params, headers: headers

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response["title"]).to eq("Titre mis à jour")
      expect(user_task1.reload.title).to eq("Titre mis à jour")
    end

    it "retourne des erreurs pour des paramètres invalides" do
      patch api_v2_task_path(user_task1), params: invalid_update_params, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key("errors")
    end

    it "retourne une erreur pour une tâche appartenant à un autre utilisateur" do
      patch api_v2_task_path(other_user_task), params: update_params, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE api_v2_task_path" do
    it "supprime une tâche" do
      expect {
        delete api_v2_task_path(user_task1), headers: headers
      }.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "retourne une erreur pour une tâche appartenant à un autre utilisateur" do
      expect {
        delete api_v2_task_path(other_user_task), headers: headers
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
