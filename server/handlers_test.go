package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestHandlePing(t *testing.T) {
	req, err := http.NewRequest("GET", "/ping", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(handlePing)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	expected := `pong`
	if rr.Body.String() != expected {
		t.Errorf("handler returned unexpected body: got %v want %v",
			rr.Body.String(), expected)
	}
}

func TestHandleGenerateUserID(t *testing.T) {
	req, err := http.NewRequest("GET", "/users/generate-id", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(handleGenerateUserID)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	if rr.Header().Get("Content-Type") != "application/json" {
		t.Errorf("handler returned wrong content type: got %v want %v",
			rr.Header().Get("Content-Type"), "application/json")
	}
}

func TestHandleCreateInvitation(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	setDB(db)

	mock.ExpectExec("INSERT INTO invitations").WillReturnResult(sqlmock.NewResult(1, 1))

	req, err := http.NewRequest("GET", "/invitations/create?userId=test-user&pseudo=test-pseudo", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(handleCreateInvitation)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	if rr.Header().Get("Content-Type") != "application/json" {
		t.Errorf("handler returned wrong content type: got %v want %v",
			rr.Header().Get("Content-Type"), "application/json")
	}
}

func TestHandleUseInvitation(t *testing.T) {
	db, mock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("an error '%s' was not expected when opening a stub database connection", err)
	}
	defer db.Close()

	setDB(db)

	rows := sqlmock.NewRows([]string{"code", "creator_user_id", "creator_pseudo", "expires_at"}).
		AddRow("test-code", "creator-user-id", "creator-pseudo", time.Now().Add(10*time.Minute))
	mock.ExpectQuery("SELECT code, creator_user_id, creator_pseudo, expires_at FROM invitations").WithArgs("test-code").WillReturnRows(rows)
	mock.ExpectExec("DELETE FROM invitations").WithArgs("test-code").WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectQuery("SELECT pseudo FROM user_pseudos").WithArgs("creator-user-id").WillReturnRows(sqlmock.NewRows([]string{"pseudo"}).AddRow("creator-pseudo"))

	body := `{"code": "test-code", "userId": "test-user", "pseudo": "test-pseudo"}`
	req, err := http.NewRequest("POST", "/invitations/use", strings.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(handleUseInvitation)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}
}
