import 'http_service.dart' as http;

const String reportIncidentEndpoint = "/incidents/report";
const String getIncidentsEndpoint = "/incidents";

class IncidentsService {
  final http.HttpService httpService = http.HttpService();

  Future<Map<String, dynamic>> reportIncident(String userID, String locationWKT, String description, String incidentType) async {
    final response = await httpService.request(
      endpoint: reportIncidentEndpoint,
      method: 'POST',
      body: {
        "userID": userID,
        "locationWKT": locationWKT,
        "description": description,
        "incidentType": incidentType,
      },
    );
    final Map<String, dynamic> data = response;
    if (data.containsKey("error")) {
      throw Exception(data["error"]);
    }
    return data;
  }

  Future<Map<String, dynamic>> getIncidentsByRoute(List<Map<String, double>> route, double tolerance) async {
    final response = await httpService.request(
      endpoint: getIncidentsEndpoint,
      method: 'POST',
      body: {
        "route": route,
        "tolerance": tolerance,
      },
    );
    final Map<String, dynamic> data = response;
    if (data.containsKey("error")) {
      throw Exception(data["error"]);
    }
    return data;
  }
}
