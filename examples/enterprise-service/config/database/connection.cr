module {{module_name}}
  module Config
    module Database
      class Connection
        getter url : String

        def initialize(@url : String = ENV["DATABASE_URL"]? || "sqlite3://./data.db")
        end
      end
    end
  end
end
