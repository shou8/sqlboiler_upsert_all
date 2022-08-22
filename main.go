package main

import (
	"context"
	"database/sql"
	_ "github.com/go-sql-driver/mysql"
	models "github.com/shou8/sqlboiler_upsert_all/models/generated"
	"github.com/volatiletech/sqlboiler/v4/boil"
)

func main() {
	boil.DebugMode = true
	db, _ := sql.Open("mysql", "root@tcp(127.0.0.1:3306)/sqlboiler_upsert_all")
	users := []*models.User{
		{ID: "1", Name: "user1_updated"},
		{ID: "2", Name: "user2_updated"},
		{ID: "3", Name: "user3_updated"},
		{ID: "4", Name: "user4_updated"},
		{ID: "5", Name: "user5_updated"},
		{ID: "6", Name: "user6_updated"},
	}
	models.UserSlice(users).UpsertAll(context.Background(), db, boil.Whitelist(models.UserTableColumns.Name), boil.Infer())
}
