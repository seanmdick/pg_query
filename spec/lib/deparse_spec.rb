require 'spec_helper'

describe PgQuery, 'deparse' do
  subject { PgQuery.parse(oneline_query).deparse }

  let (:oneline_query) { query.gsub(/\s+/, ' ').gsub('( ', '(').gsub(' )', ')').strip }

  context 'SELECT' do
    context 'basic statement' do
      let(:query) { 'SELECT a AS b FROM x WHERE y = 5 AND z = y' }
      it { is_expected.to eq query }
    end

    context 'complex SELECT statement' do
      let(:query) { "SELECT memory_total_bytes, memory_swap_total_bytes - memory_swap_free_bytes AS swap, date_part($0, s.collected_at) AS collected_at FROM snapshots s JOIN system_snapshots ON snapshot_id = s.id WHERE s.database_id = $0 AND s.collected_at >= $0 AND s.collected_at <= $0 ORDER BY collected_at ASC" }
      it { is_expected.to eq query }
    end

    context 'simple WITH statement' do
      let(:query) { 'WITH t AS (SELECT random() AS x FROM generate_series(1, 3)) SELECT * FROM t' }
      it { is_expected.to eq query }
    end

    context 'complex WITH statement' do
      let(:query) {
        """
        WITH RECURSIVE employee_recursive(distance, employee_name, manager_name) AS (
          SELECT 1, employee_name, manager_name
          FROM employee
          WHERE manager_name = 'Mary'
        UNION ALL
          SELECT er.distance + 1, e.employee_name, e.manager_name
          FROM employee_recursive er, employee e
          WHERE er.employee_name = e.manager_name
        )
        SELECT distance, employee_name FROM employee_recursive
        """
      }
      it { is_expected.to eq oneline_query }
    end

    context 'LATERAL' do
      let(:query) { 'SELECT m.name AS mname, pname FROM manufacturers m, LATERAL get_product_names(m.id) pname' }
      it { is_expected.to eq query }
    end

    context 'LATERAL JOIN' do
      let(:query) {
        """
        SELECT m.name AS mname, pname
          FROM manufacturers m LEFT JOIN LATERAL get_product_names(m.id) pname ON true
        """
      }
      it { is_expected.to eq oneline_query }
    end

    context 'omitted FROM clause' do
      let(:query) { 'SELECT 2 + 2' }
      it { is_expected.to eq query }
    end
  end

  context 'basic INSERT statements' do
    let(:query) { "INSERT INTO x (y, z) VALUES (1, 'abc')" }
    it { is_expected.to eq query }
  end

  context 'basic UPDATE statements' do
    let(:query) { "UPDATE x SET y = 1 WHERE z = 'abc'" }
    it { is_expected.to eq query }
  end
end
