import Foundation

/// Sezione attualmente selezionata nella sidebar, condivisa tra la finestra principale
/// e la barra dei menù: permette a un pulsante nella barra dei menù di far comparire la
/// finestra già aperta sulla sezione giusta (es. "Pulizia Automatica").
final class NavigationState: ObservableObject {
    @Published var selection: AppSection? = .dashboard
}
