SELECT
    sm_type,
    COUNT(*) AS mode_count,
    COUNT(DISTINCT sm_ship_mode_id) AS distinct_ids
FROM tpcds.ship_mode
WHERE sm_contract IN ('UaAJjKDnL4gTOqbpj', 'I3uCelXtjP')
  AND sm_code = 'AIR'
GROUP BY sm_type
ORDER BY mode_count DESC
LIMIT 10
