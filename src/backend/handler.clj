(ns backend.handler
  (:require [clojure.data.json :as json]
            [ring.util.response :as resp]
            [backend.db :as db]
            [next.jdbc.result-set :as rs]))

(defn- format-todo [row]
  (-> row
      (update :done #(pos? (int %)))))

(defn get-todos [_request]
  (let [rows (db/all-todos)]
    (resp/response (map format-todo rows))))

(defn create-todo [request]
  (let [body (:body request)
        title (:title body)]
    (if (and title (not (clojure.string/blank? title)))
      (do
        (db/create-todo! title)
        (resp/response {:ok true}))
      (resp/status (resp/response {:error "title required"}) 400))))

(defn update-todo [request]
  (let [id (Integer/parseInt (get-in request [:path-params :id]))
        body (:body request)
        done (:done body)]
    (db/update-todo! id {:done (if done 1 0)})
    (resp/response {:ok true})))

(defn delete-todo [request]
  (let [id (Integer/parseInt (get-in request [:path-params :id]))]
    (db/delete-todo! id)
    (resp/response {:ok true})))
