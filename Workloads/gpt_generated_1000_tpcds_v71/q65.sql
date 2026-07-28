WITH filtered AS (
  SELECT
    sr.sr_return_amt,
    sr.sr_reversed_charge,
    i.i_brand,
    i.i_formulation,
    regexp_extract(i.i_formulation, '(\\d+)([a-z]+)(\\d+)', 2) AS formulation_alpha,
    s.s_manager,
    s.s_city,
    s.s_state,
    CASE
      WHEN sr.sr_return_amt > 100 THEN 'large'
      WHEN sr.sr_return_amt > 0 THEN 'small'
      ELSE 'none'
    END AS return_size
  FROM tpcds.store_returns sr
  JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
  JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
  WHERE regexp_like(i.i_formulation, '^\\d{9}[a-z]+')
    AND s.s_manager LIKE '%John%'
    AND substring(i.i_item_id, 1, 3) = '001'
),

agg AS (
  SELECT
    s_manager,
    CONCAT(s_city, ', ', s_state) AS location,
    COUNT(DISTINCT i_brand) AS distinct_brands,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(CASE WHEN sr_reversed_charge > 0 THEN sr_reversed_charge ELSE 0 END) AS total_reversed_charge,
    SUM(CASE WHEN return_size = 'large' THEN 1 ELSE 0 END) AS large_return_cnt
  FROM filtered
  GROUP BY s_manager, CONCAT(s_city, ', ', s_state)
),

high AS (
  SELECT *
  FROM agg
  WHERE total_return_amount > 1000
),

low AS (
  SELECT *
  FROM agg
  WHERE total_return_amount <= 1000
)

SELECT
  s_manager,
  location,
  distinct_brands,
  total_return_amount,
  total_reversed_charge,
  large_return_cnt,
  CASE
    WHEN total_return_amount > 5000 THEN 'VIP'
    WHEN total_return_amount > 2000 THEN 'Gold'
    ELSE 'Silver'
  END AS tier
FROM (
  SELECT * FROM high
  UNION DISTINCT
  SELECT * FROM low
) combined
ORDER BY total_return_amount DESC
LIMIT 100
