
import '../model/subject_model.dart';


class VoteRepository {

  Future<String?> sendVoteToBackend(SubjectModel data) async {
    // --- ICI SE FERA L'APPEL BACKEND ---
    // Exemple avec le package Dio ou Http :
    // try {
    //   var response = await dio.post('https://ton-api.com/subjects', data: data.toJson());
    //   return response.data['share_link'];
    // } catch (e) { return null; }

    // Simulation pour que ton front fonctionne maintenant :
    await Future.delayed(const Duration(seconds: 2));
    return "https://securevote.app/v/mock_id_123";
  }
}