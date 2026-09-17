# frozen_string_literal: true

# Configuración por defecto para la gema Pagy (Sports Hub)
# Pagy 9 utiliza :limit para definir la cantidad de registros por página (10 solicitados).
Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:overflow] = :last_page if defined?(Pagy::DEFAULT)
