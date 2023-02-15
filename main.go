package main

import (
	"database/sql"
	"fmt"
	_ "github.com/jackc/pgx"
	"html/template"
	"log"
	"net/http"
)

type log_pass struct {
	login    string
	password string
}

var database *sql.DB

func IndexHandler(w http.ResponseWriter, r *http.Request) {

	info, err := database.Query("select * from FindPass('Ivan', 'Site_1')")
	if err != nil {
		log.Println(err)
	}
	defer info.Close()
	info_unit := []log_pass{}

	for info.Next() {
		p := log_pass{}
		err := info.Scan(&p.login, &p.password)
		if err != nil {
			fmt.Println(err)
			continue
		}
		info_unit = append(info_unit, p)
	}

	tmpl, _ := template.ParseFiles("templates/index.html")
	tmpl.Execute(w, info_unit)
}

func main() {
	db, err := sql.Open("Postgres", "postgres:db432goGA@/PassManager")

	if err != nil {
		log.Println(err)
	}

	database = db
	defer db.Close()
	http.HandleFunc("/", IndexHandler)

	fmt.Println("Server is listening...")
	http.ListenAndServe(":8181", nil)
}
