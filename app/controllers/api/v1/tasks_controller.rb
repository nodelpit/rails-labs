class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: [ :show, :update, :destroy ]
  def index
    tasks = current_user.tasks
    render json: tasks
  end

  def show
    render json: @task
  end

  def create
    # Associer la nouvelle tâche à l'utilisateur authentifié
    task = current_user.tasks.build(task_params)
    if task.save
      render json: task, status: :created
    else
      render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    head :no_content
  end

  private

  def set_task
    # Rechercher la tâche uniquement parmi les tâches de l'utilisateur courant
    @task = current_user.tasks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tâche non trouvée" }, status: :not_found
  end

  def task_params
    params.require(:task).permit(:title, :description, :completed)
  end
end
