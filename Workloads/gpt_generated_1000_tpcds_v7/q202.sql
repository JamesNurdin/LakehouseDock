WITH filtered AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    s.s_city AS city,
    s.s_state AS state,
    s.s_tax_percentage AS tax_percentage,
    s.s_market_manager AS market_manager,
    s.s_street_type AS street_type,
    d.d_date AS date,
    d.d_year AS year,
    d.d_week_seq AS week_seq,
    d.d_day_name AS day_name
  FROM store s
  JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
  WHERE s.s_street_type IN ('Ct.', 'Drive', 'Boulevard')
    AND s.s_tax_percentage BETWEEN 0.02 AND 0.08
    AND s.s_market_manager NOT IN ('Michael Redding')
    AND s.s_state = 'CA'
    AND d.d_year = 2002
    AND d.d_week_seq BETWEEN 8 AND 15
    AND d.d_holiday = 'N'
)
SELECT
  store_id,
  store_name,
  city,
  state,
  tax_percentage,
  market_manager,
  street_type,
  date,
  year,
  week_seq,
  day_name,
  ROW_NUMBER() OVER (PARTITION BY state ORDER BY tax_percentage DESC) AS tax_rank_state,
  RANK() OVER (PARTITION BY year ORDER BY week_seq) AS week_rank_year,
  CASE
    WHEN tax_percentage > 0.05 THEN 'High Tax'
    WHEN tax_percentage > 0.03 THEN 'Medium Tax'
    ELSE 'Low Tax'
  END AS tax_category
FROM filtered
ORDER BY tax_rank_state, week_rank_year
LIMIT 100
