package main

import (
	"database/sql"
)

func main() {
	db, _ := sql.Open("mysql", "root@tcp(mysql)/sqlboiler_upsert_all")
	return
}
