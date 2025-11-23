(ns backend.db
  (:require [next.jdbc :as jdbc]
            [next.jdbc.sql :as sql]))

(def db-file "todo.db")
(def ds (atom nil))

(defn init-db []
  (let [url (str "jdbc:sqlite:" db-file)
        datasource (jdbc/get-datasource {:jdbcUrl url})]
    (reset! ds datasource)
    ;; cria tabela se nao existir
    (jdbc/execute! datasource ["CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)"])
    datasource))

(defn all-todos []
  (sql/query @ds ["SELECT id, title, done FROM todos ORDER BY id ASC"]))

(defn create-todo! [title]
  (sql/insert! @ds :todos {:title title :done 0}))

(defn update-todo! [id data]
  (sql/update! @ds :todos data {:id id}))

(defn delete-todo! [id]
  (sql/delete! @ds :todos {:id id}))
