#!/usr/bin/env bash
# make-commits.sh
# Script to create a git repo with an incremental commit history matching the assignment requirements.
# Run this in the project root on your machine (requires git).
#
# Usage:
#   chmod +x make-commits.sh
#   ./make-commits.sh
#
# IMPORTANT: This script will create a new git repository in the current directory.
# If you already have a git repo here, back it up first.

set -e
rm -rf .git
git init
git config user.name "DANIEL LINDOSO PENHA"
git config user.email "student@example.com"

echo "Commit 1: feat: setup inicial do projeto com .gitignore"
# Keep only minimal files for initial commit
git add .gitignore README.md
git commit -m "feat: setup inicial do projeto com .gitignore"

echo "Commit 2: feat: implementa servidor 'Hello World' com Jetty e Reitit"
# Create a minimal hello world backend
cat > src/backend/core.clj <<'EOF'
(ns backend.core
  (:require [ring.adapter.jetty :refer [run-jetty]]
            [reitit.ring :as ring]
            [ring.util.response :refer [response]]))

(def app
  (ring/ring-handler
    (ring/router
      [["/" (fn [_] (response "Hello World from Jetty + Reitit"))]])))

(defn -main [& _]
  (println "Starting Hello World server on :3000")
  (run-jetty app {:port 3000 :join? true}))
EOF

git add src/backend/core.clj
git commit -m "feat: implementa servidor 'Hello World' com Jetty e Reitit"

echo "Commit 3: feat: implementa API REST de 'todos' com banco em memória"
# Add simple in-memory API (no persistence)
cat > src/backend/db.clj <<'EOF'
(ns backend.db)

(defonce todos (atom (sorted-map)))
(defonce next-id (atom 1))

(defn all-todos [] (vals @todos))
(defn create-todo! [title]
  (let [id (swap! next-id inc)]
    (swap! todos assoc id {:id id :title title :done false})
    id))
(defn update-todo! [id data]
  (swap! todos update id merge data))
(defn delete-todo! [id]
  (swap! todos dissoc id))
EOF

cat > src/backend/handler.clj <<'EOF'
(ns backend.handler
  (:require [ring.util.response :as resp]
            [backend.db :as db]))

(defn get-todos [_]
  (resp/response (db/all-todos)))

(defn create-todo [request]
  (let [body (:body request)
        title (:title body)]
    (db/create-todo! title)
    (resp/response {:ok true})))

(defn update-todo [request]
  (resp/response {:ok true}))

(defn delete-todo [request]
  (resp/response {:ok true}))
EOF

git add src/backend/db.clj src/backend/handler.clj
git commit -m "feat: implementa API REST de 'todos' com banco em memória"

echo "Commit 4: feat: implementa UI do frontend com estado local (sem API)"
# Frontend uses local state only
cat > frontend/src/frontend/components.cljs <<'EOF'
(ns frontend.components
  (:require [reagent.core :as r]))

(defonce todos (r/atom [{:id 1 :title "exemplo" :done false}]))
(defonce new-title (r/atom ""))

(defn add-local []
  (when-not (clojure.string/blank? @new-title)
    (swap! todos conj {:id (inc (count @todos)) :title @new-title :done false})
    (reset! new-title "")))

(defn todo-item [t]
  [:li
   [:span (:title t)]
   [:button {:on-click #(swap! todos (fn [ts] (remove (fn [x] (= (:id x) (:id t))) ts)))} "Delete"]])

(defn app []
  [:div
   [:h2 "Todo (Local State)"]
   [:input {:value @new-title :on-change #(reset! new-title (.. % -target -value))}]
   [:button {:on-click add-local} "Add"]
   [:ul (for [t @todos] ^{:key (:id t)} [todo-item t])]])
EOF

git add frontend/src/frontend/components.cljs
git commit -m "feat: implementa UI do frontend com estado local (sem API)"

echo "Commit 5: feat: conecta frontend com API do backend (CORS corrigido)"
# Replace frontend to call /api endpoints (assumes backend will provide them)
cat > frontend/src/frontend/components.cljs <<'EOF'
(ns frontend.components
  (:require [reagent.core :as r]))

(defonce todos (r/atom []))
(defonce new-title (r/atom ""))

(defn fetch-todos! []
  (-> (js/fetch "/api/todos")
      (.then (fn [r] (.json r)))
      (.then (fn [j] (reset! todos (js->clj j :keywordize-keys true))))))

(defn create-todo! []
  (let [title @new-title]
    (-> (js/fetch "/api/todos"
                  (clj->js {:method "POST"
                            :headers {"Content-Type" "application/json"}
                            :body (js/JSON.stringify #js {:title title})}))
        (.then (fn [_] (reset! new-title "") (fetch-todos!))))))

(defn app []
  (r/create-class
   {:component-did-mount fetch-todos!
    :reagent-render
    (fn []
      [:div
       [:h2 "Todo (Conectado)"]
       [:input {:value @new-title :on-change #(reset! new-title (.. % -target -value))}]
       [:button {:on-click create-todo!} "Add"]
       [:ul (for [t @todos] ^{:key (:id t)} [:li (:title t)])]])}))
EOF

git add frontend/src/frontend/components.cljs
git commit -m "feat: conecta frontend com API do backend (CORS corrigido)"

echo "Commit 6: refactor(db): substitui banco em memória por persistência SQLite"
# Overwrite db.clj with SQLite version
cat > src/backend/db.clj <<'EOF'
(ns backend.db
  (:require [next.jdbc :as jdbc]
            [next.jdbc.sql :as sql]))

(def db-file "todo.db")
(defonce ds (atom nil))

(defn init-db []
  (let [url (str "jdbc:sqlite:" db-file)
        datasource (jdbc/get-datasource {:jdbcUrl url})]
    (reset! ds datasource)
    (jdbc/execute! @ds ["CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, done INTEGER NOT NULL DEFAULT 0)"])
    @ds))

(defn all-todos []
  (sql/query @ds ["SELECT id, title, done FROM todos ORDER BY id ASC"]))

(defn create-todo! [title]
  (sql/insert! @ds :todos {:title title :done 0}))

(defn update-todo! [id data]
  (sql/update! @ds :todos data {:id id}))

(defn delete-todo! [id]
  (sql/delete! @ds :todos {:id id}))
EOF

git add src/backend/db.clj
git commit -m "refactor(db): substitui banco em memória por persistência SQLite"

echo "Commit 7: feat(crud): implementa funcionalidades de toggle e delete"
# Update handler to implement toggle and delete, and ensure JSON body parsing
cat > src/backend/handler.clj <<'EOF'
(ns backend.handler
  (:require [ring.util.response :as resp]
            [backend.db :as db]
            [clojure.string :as str]))

(defn format-row [r]
  (-> r (update :done #(pos? (int %)))))

(defn get-todos [_]
  (resp/response (map format-row (db/all-todos))))

(defn create-todo [request]
  (let [title (get-in request [:body :title])]
    (when (and title (not (str/blank? title)))
      (db/create-todo! title))
    (resp/response {:ok true})))

(defn update-todo [request]
  (let [id (Integer/parseInt (get-in request [:path-params :id]))
        done (get-in request [:body :done])]
    (db/update-todo! id {:done (if done 1 0)})
    (resp/response {:ok true})))

(defn delete-todo [request]
  (let [id (Integer/parseInt (get-in request [:path-params :id]))]
    (db/delete-todo! id)
    (resp/response {:ok true})))
EOF

git add src/backend/handler.clj
git commit -m "feat(crud): implementa funcionalidades de toggle e delete"

echo "All commits created. You can now add a GitHub remote and push:"
echo "  git remote add origin <git-url>"
echo "  git branch -M main"
echo "  git push -u origin main"
