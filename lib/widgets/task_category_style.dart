import 'package:flutter/material.dart';

/// NEW — one place that decides how a task looks for each volunteer role:
/// icon + wording. Used by the volunteer "My Tasks" list and the task detail
/// screen so a pickup, a blood-donation drive, a medical camp, etc. each read
/// differently without needing separate dashboards.
class TaskCategoryStyle {
  final IconData icon;
  final String locationLabel;

  const TaskCategoryStyle({required this.icon, required this.locationLabel});

  static TaskCategoryStyle of(String category) {
    switch (category) {
      case 'Resource Pickup':
        return const TaskCategoryStyle(icon: Icons.inventory_2_rounded, locationLabel: 'Pickup Address');
      case 'Blood Donation':
        return const TaskCategoryStyle(icon: Icons.bloodtype_rounded, locationLabel: 'Donation Venue');
      case 'Emergency Response':
        return const TaskCategoryStyle(icon: Icons.emergency_rounded, locationLabel: 'Emergency Location');
      case 'Relief Distribution':
        return const TaskCategoryStyle(icon: Icons.volunteer_activism_rounded, locationLabel: 'Distribution Point');
      case 'Medical Camps':
        return const TaskCategoryStyle(icon: Icons.medical_services_rounded, locationLabel: 'Camp Venue');
      case 'Ration Drive':
        return const TaskCategoryStyle(icon: Icons.shopping_basket_rounded, locationLabel: 'Distribution Point');
      case 'Teaching':
        return const TaskCategoryStyle(icon: Icons.school_rounded, locationLabel: 'Class Location');
      case 'Event Management':
        return const TaskCategoryStyle(icon: Icons.event_rounded, locationLabel: 'Event Venue');
      case 'Volunteering & Management':
        return const TaskCategoryStyle(icon: Icons.groups_rounded, locationLabel: 'Location');
      default:
        return const TaskCategoryStyle(icon: Icons.assignment_rounded, locationLabel: 'Location');
    }
  }
}