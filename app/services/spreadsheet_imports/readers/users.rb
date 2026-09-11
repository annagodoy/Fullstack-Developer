class SpreadsheetImports::Readers::Users
  class InvalidSpreadsheet < StandardError; end

  REQUIRED_HEADERS = %w[ full_name email ].freeze
  ALLOWED_HEADERS  = %w[ full_name email role].freeze

  MAX_ROWS = 5000

  def initialize(path, extension:)
    @path = path
    @extension = extension.to_s.downcase
  end

  def call
    unless @extension.in?(%w[ csv xlsx ])
      raise InvalidSpreadsheet, "Unsupported file format."
    end

    sheet = Roo::Spreadsheet.open(@path, extension: @extension).sheet(0)
    last_row = sheet.last_row.to_i

    if last_row.zero?
      raise InvalidSpreadsheet, "The file is empty."
    end

    if last_row > MAX_ROWS + 1
      raise InvalidSpreadsheet, "The file must have at most #{MAX_ROWS} data rows."
    end

    headers = sheet.row(1).map do |value|
      value.to_s.delete_prefix("\uFEFF").strip.downcase
    end

    validate_headers!(headers)

    rows = (2..last_row).filter_map do |number|
      values = sheet.row(number)
      next if values.all?(&:blank?)

      attributes = headers.zip(values).to_h
        .transform_values { |value| value.to_s.strip }

      attributes["role"] = attributes["role"].presence || "member"

      { row_number: number, attributes: attributes }
    end

    if rows.empty?
      raise InvalidSpreadsheet, "The spreadsheet has no data rows."
    end

    rows
  end

  private

  def validate_headers!(headers)
    if headers.any?(&:blank?) || headers.uniq.length != headers.length
      raise InvalidSpreadsheet, "Headers must be present."
    end

    missing = REQUIRED_HEADERS - headers
    if missing.any?
      raise InvalidSpreadsheet, "Missing columns: #{missing.join(', ')}."
    end

    unknown = headers - ALLOWED_HEADERS
    if unknown.any?
      raise InvalidSpreadsheet, "Unknown columns: #{unknown.join(', ')}."
    end
  end
end
