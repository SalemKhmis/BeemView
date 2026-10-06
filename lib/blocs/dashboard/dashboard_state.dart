import 'package:equatable/equatable.dart';

import '../../models/dashboard_analytics.dart';

/// States for the home dashboard analytics flow.
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any analytics are loaded.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Analytics are being loaded or refreshed.
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Analytics successfully loaded and aggregated.
class DashboardLoaded extends DashboardState {
  final DashboardAnalytics analytics;

  const DashboardLoaded(this.analytics);

  @override
  List<Object?> get props => [analytics];
}

/// Failed to load dashboard analytics.
class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
