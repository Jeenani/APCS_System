import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasks({String? status, String? search, String? sort, int? priorityId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String path = '/tasks?';
      if (status != null) path += 'status=$status&';
      if (search != null && search.isNotEmpty) path += 'search=$search&';
      if (sort != null) path += 'sort=$sort&';
      if (priorityId != null) path += 'priority_id=$priorityId&';

      final response = await ApiClient.get(path);
      final List tasksJson = response['tasks'] ?? [];
      _tasks = tasksJson.map((j) => TaskModel.fromJson(j)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<TaskModel?> getTask(int id) async {
    try {
      final response = await ApiClient.get('/tasks/$id');
      return TaskModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      await ApiClient.post('/tasks', data);
      await loadTasks();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    try {
      await ApiClient.put('/tasks/$id', data);
      await loadTasks();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await ApiClient.delete('/tasks/$id');
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(int taskId) async {
    try {
      final response = await ApiClient.get('/tasks/$taskId/history');
      return List<Map<String, dynamic>>.from(response['history'] ?? []);
    } catch (e) {
      return [];
    }
  }
}
