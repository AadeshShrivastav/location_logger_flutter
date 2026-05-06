import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/firebase_datasource.dart';

class AuthController extends GetxController {
  final AuthDatasource authDatasource;
  final FirebaseDatasource firebaseDatasource;

  AuthController(this.authDatasource, this.firebaseDatasource) {
    _bindAuthState();
  }

  final Rxn<User> currentUser = Rxn<User>();
  final RxBool isLoading = false.obs;
  final RxBool isResolvingRole = false.obs;
  final RxString role = "user".obs;
  final RxString errorMessage = "".obs;

  void _bindAuthState() {
    currentUser.bindStream(authDatasource.authStateChanges());
    ever<User?>(currentUser, (user) async {
      if (user == null) {
        role.value = "user";
        isResolvingRole.value = false;
        return;
      }
      isResolvingRole.value = true;
      role.value = await firebaseDatasource.getUserRole(user.uid);
      isResolvingRole.value = false;
    });
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";
      final cred = await authDatasource.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        currentUser.value = user;
        isResolvingRole.value = true;
        final userRole = await firebaseDatasource.getUserRole(user.uid);
        await firebaseDatasource.createOrUpdateUserProfile(
          userId: user.uid,
          email: user.email ?? email.trim(),
          role: userRole,
        );
        role.value = userRole;
        isResolvingRole.value = false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? e.code;
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final cred = await authDatasource.signUpWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        errorMessage.value = "Could not create user";
        return false;
      }

      currentUser.value = user;
      await firebaseDatasource.createOrUpdateUserProfile(
        userId: user.uid,
        email: user.email ?? email.trim(),
        role: "user",
      );
      role.value = "user";
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? e.code;
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await authDatasource.signOut();
  }
}
