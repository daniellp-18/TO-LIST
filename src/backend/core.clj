(ns backend.core
  (:require
    [reitit.ring :as ring]
    [reitit.ring.middleware.parameters :refer [parameters-middleware]]
    [reitit.ring.middleware.muuntaja :refer [format-negotiate-middleware]]
    [ring.adapter.jetty :refer [run-jetty]]
    [ring.middleware.cors :refer [wrap-cors]]
    [ring.middleware.json :refer [wrap-json-body wrap-json-response]]
    [backend.db :as db]
    [backend.handler :as handler]))

(def app
  (-> (ring/ring-handler
        (ring/router
          [["/api"
            ["/todos" {:get handler/get-todos
                       :post handler/create-todo}]
            ["/todos/:id" {:put handler/update-todo
                           :delete handler/delete-todo}]]]
          {:data {:middleware [parameters-middleware]}}))
      (wrap-json-body {:keywords? true :bigdecimals? false})
      wrap-json-response
      (wrap-cors :access-control-allow-origin [#".*"]
                 :access-control-allow-methods [:get :post :put :delete :options]
                 :access-control-allow-headers ["content-type"])))

(defn -main [& args]
  (println "Iniciando DB...")
  (db/init-db)
  (println "Rodando servidor na porta 3000")
  (run-jetty app {:port 3000 :join? true}))
