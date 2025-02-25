require 'rails_helper'

RSpec.describe "Api::V1::Tasks", type: :request do
  let!(:task) { Task.create(title: "Test Task", description: "Test Descrption", completed: false) }

  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/tasks"
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/tasks/#{task.id}"
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['id']).to eq(task.id)
    end
  end

  describe "POST /create" do
    it "creates a new tasks" do
      post "/api/v1/tasks", params: {
        task: {
          title: "New Task",
          description: "New Description",
          completed: false
        }
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['title']).to eq("New Task")
    end
  end

  describe "PUT /update" do
    it "updates an existing task" do
      put "/api/v1/tasks/#{task.id}", params: {
        task: {
          title: "Updated Task"
        }
      }
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['title']).to eq("Updated Task")
    end
  end

  describe "DELETE /destroy" do
    it "deletes a task" do
      delete "/api/v1/tasks/#{task.id}"
      expect(response).to have_http_status(:no_content)
      expect(Task.exists?(task.id)).to be_falsey
    end
  end
end
