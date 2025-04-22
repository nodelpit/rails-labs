require 'rails_helper'
RSpec.describe "Api::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let!(:token) { user.generate_api_token[1] }
  # Important : associer la tâche à l'utilisateur
  let!(:task) { create(:task, user: user) }

  describe "GET /index" do
    it "returns http success" do
      get api_v1_tasks_path, headers: { "X-Api-Token" => token }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get api_v1_task_path(task), headers: { "X-Api-Token" => token }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['id']).to eq(task.id)
    end
  end

  describe "POST /create" do
    it "creates a new task" do
      post api_v1_tasks_path,
        params: { task: { title: "New Task", description: "New Description", completed: false } },
        headers: { "X-Api-Token" => token }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['title']).to eq("New Task")
      # Vérifier que la tâche est associée à l'utilisateur
      expect(Task.last.user_id).to eq(user.id)
    end
  end

  describe "PUT /update" do
    it "updates an existing task" do
      put api_v1_task_path(task),
        params: { task: { title: "Updated Task" } },
        headers: { "X-Api-Token" => token }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['title']).to eq("Updated Task")
    end
  end

  describe "DELETE /destroy" do
    it "deletes a task" do
      delete api_v1_task_path(task), headers: { "X-Api-Token" => token }
      expect(response).to have_http_status(:no_content)
      expect(Task.exists?(task.id)).to be_falsey
    end
  end
end
