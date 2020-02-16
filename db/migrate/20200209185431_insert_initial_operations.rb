class InsertInitialOperations < ActiveRecord::Migration[5.2]
  def change
    operations = ["入庫", "出庫", "破棄"]
    operations.each do |operation|
      Operation.create(name: operation)
    end
  end
end
