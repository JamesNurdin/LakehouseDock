WITH
  sr_agg AS (
    SELECT
      sr.sr_store_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      AVG(sr.sr_fee) AS avg_fee
    FROM store_returns sr
    JOIN item i1 ON sr.sr_item_sk = i1.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd1 ON sr.sr_hdemo_sk = hd1.hd_demo_sk
    JOIN store s1 ON sr.sr_store_sk = s1.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    GROUP BY sr.sr_store_sk
  ),
  high_return_stores AS (
    SELECT DISTINCT s.s_store_id
    FROM sr_agg a
    JOIN store s ON a.sr_store_sk = s.s_store_sk
    WHERE a.total_return_amt > 1000
  ),
  tax_high_stores AS (
    SELECT DISTINCT s.s_store_id
    FROM store s
    WHERE s.s_tax_percentage > 0.05
  ),
  ca_stores AS (
    SELECT DISTINCT s.s_store_id
    FROM store s
    WHERE s.s_state = 'CA'
  ),
  union_set AS (
    SELECT s_store_id FROM high_return_stores
    UNION
    SELECT s_store_id FROM tax_high_stores
  ),
  intersect_set AS (
    SELECT s_store_id FROM union_set
    INTERSECT
    SELECT s_store_id FROM ca_stores
  )
SELECT
  s.s_store_id,
  s.s_store_name,
  a.total_return_amt,
  a.avg_fee,
  p.p_promo_name,
  loc AS location_part,
  COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM intersect_set i
JOIN store s ON i.s_store_id = s.s_store_id
JOIN sr_agg a ON s.s_store_sk = a.sr_store_sk
JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN item i1 ON sr.sr_item_sk = i1.i_item_sk
JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
JOIN promotion p ON p.p_item_sk = i2.i_item_sk
CROSS JOIN UNNEST(ARRAY[s.s_city, s.s_state]) AS u(loc)
WHERE a.total_return_amt > (
  SELECT AVG(total_return_amt) FROM sr_agg
)
GROUP BY s.s_store_id, s.s_store_name, a.total_return_amt, a.avg_fee, p.p_promo_name, loc
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY a.total_return_amt DESC
LIMIT 100
