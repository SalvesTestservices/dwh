class DatalabQueryAnalyzer
  COMPLEXITY_INDICATORS = {
    time_comparison: ['vergelijk', 'vorige', 'periode', 'jaar', 'maand'],
    calculations: ['gemiddelde', 'percentage', 'totaal', 'verschil'],
    grouping: ['per', 'groepeer', 'verdeel'],
    multiple_entities: ['en', 'versus', 'tegenover']
  }

  def self.analyze(query)
    complexity = {
      is_complex: false,
      needs_cte: false,
      aspects: []
    }

    COMPLEXITY_INDICATORS.each do |aspect, keywords|
      if keywords.any? { |keyword| query.downcase.include?(keyword) }
        complexity[:is_complex] = true
        complexity[:needs_cte] = true
        complexity[:aspects] << aspect
      end
    end

    complexity
  end
end 