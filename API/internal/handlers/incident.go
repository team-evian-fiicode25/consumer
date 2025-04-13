package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/team-evian-fiicode25/business-logic/data"
	"github.com/team-evian-fiicode25/business-logic/incident"
)

type IncidentHandler struct{}

func NewIncidentHandler() *IncidentHandler {
	return &IncidentHandler{}
}

func (h *IncidentHandler) Report(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "only POST allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		UserID       string `json:"userID"`
		LocationWKT  string `json:"locationWKT"`
		Description  string `json:"description"`
		IncidentType string `json:"incidentType"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("invalid JSON payload: %v", err), http.StatusBadRequest)
		return
	}
	inc, err := incident.ReportTrafficIncident(
		req.UserID,
		req.LocationWKT,
		req.Description,
		req.IncidentType,
	)
	if err != nil {
		http.Error(w, fmt.Sprintf("error reporting incident: %v", err), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(inc)
}

func (h *IncidentHandler) Get(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "only POST allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		Route     []incident.LatLng `json:"route"`
		Tolerance float64           `json:"tolerance"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("invalid JSON payload: %v", err), http.StatusBadRequest)
		return
	}
	if len(req.Route) == 0 {
		http.Error(w, "route array is empty", http.StatusBadRequest)
		return
	}
	if req.Tolerance == 0 {
		req.Tolerance = 50.0
	}
	incs, err := incident.GetOpenTrafficIncidentsByRoute(req.Route, req.Tolerance)
	if err != nil {
		http.Error(w, fmt.Sprintf("error fetching incidents: %v", err), http.StatusInternalServerError)
		return
	}
	resp := struct {
		Incidents []data.TrafficIncident `json:"incidents"`
		Status    string                 `json:"status"`
	}{
		Incidents: incs,
		Status:    "OK",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
