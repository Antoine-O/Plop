package main

import (
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/lib/pq"
)

func TestDbGetUserDeviceTokens(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	setDB(db)

	rows := sqlmock.NewRows([]string{"tokens"}).
		AddRow(pq.Array([]string{"token1", "token2"}))
	mock.ExpectQuery("SELECT tokens FROM user_device_tokens").WithArgs("test-user").WillReturnRows(rows)

	tokens, err := dbGetUserDeviceTokens("test-user")
	if err != nil {
		t.Errorf("error was not expected while getting device tokens: %s", err)
	}

	if len(tokens) != 2 {
		t.Errorf("expected 2 tokens, got %d", len(tokens))
	}
}
