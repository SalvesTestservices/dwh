namespace :datalab do
  desc "Train the LLM model with database schema and sample data"
  task train: :environment do
    trainer = DatalabTrainer.new
    trainer.train
  end
end 