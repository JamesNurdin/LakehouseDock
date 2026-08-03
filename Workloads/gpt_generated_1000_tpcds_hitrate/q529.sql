WITH sampled_store_returns AS (
  SELECT *
  FROM store_returns TABLESAMPLE BERNOULLI (10)
),

store_daily AS (
  SELECT
    s.s_store_id,
    d.d_date,
    SUM(sr.sr_return_amt) AS daily_return_amt,
    SUM(sr.sr_return_quantity) AS daily_return_qty
  FROM sampled_store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_store_id, d.d_date
),

store_return_agg AS (
  SELECT
    s_store_id,
    d_date,
    daily_return_amt,
    daily_return_qty,
    SUM(daily_return_amt) OVER (PARTITION BY s_store_id ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return_amt,
    LAG(daily_return_amt) OVER (PARTITION BY s_store_id ORDER BY d_date) AS prev_day_return_amt
  FROM store_daily
),

web_daily AS (
  SELECT
    c.c_customer_id AS entity_id,
    d.d_date,
    SUM(wr.wr_return_amt) AS daily_return_amt,
    SUM(wr.wr_return_quantity) AS daily_return_qty
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
  GROUP BY c.c_customer_id, d.d_date
),

web_return_agg AS (
  SELECT
    entity_id,
    d_date,
    daily_return_amt,
    daily_return_qty,
    SUM(daily_return_amt) OVER (PARTITION BY entity_id ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return_amt,
    LAG(daily_return_amt) OVER (PARTITION BY entity_id ORDER BY d_date) AS prev_day_return_amt
  FROM web_daily
),

combined AS (
  SELECT s_store_id AS entity_id, d_date, daily_return_amt, daily_return_qty, running_total_return_amt, prev_day_return_amt
  FROM store_return_agg
  UNION
  SELECT entity_id, d_date, daily_return_amt, daily_return_qty, running_total_return_amt, prev_day_return_amt
  FROM web_return_agg
),

active_entities AS (
  SELECT s.s_store_id AS entity_id
  FROM store s
  WHERE s.s_closed_date_sk IS NULL
    AND s.s_gmt_offset > 0
),

final_set AS (
  SELECT *
  FROM combined
  WHERE entity_id IN (SELECT entity_id FROM active_entities)
  EXCEPT
  SELECT entity_id, d_date, daily_return_amt, daily_return_qty, running_total_return_amt, prev_day_return_amt
  FROM combined
  WHERE daily_return_amt = 0
)
SELECT *
FROM final_set
ORDER BY entity_id, d_date
LIMIT 100
