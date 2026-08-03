WITH joined_data AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_fee,
    c.c_customer_sk,
    c.c_birth_year,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    td.t_hour,
    wr.wr_return_amt,
    wr.wr_return_ship_cost
  FROM catalog_returns cr
  FULL OUTER JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
  WHERE cr.cr_return_amount > 20
    AND cr.cr_fee >= 1
    AND c.c_birth_year BETWEEN 1950 AND 1990
    AND td.t_hour BETWEEN 6 AND 22
    AND sr.sr_return_quantity > 0
    AND wr.wr_return_ship_cost > 0
),
expanded AS (
  SELECT
    jd.*, 
    amt_val
  FROM joined_data jd
  CROSS JOIN LATERAL (
    SELECT ARRAY[jd.cr_return_amount, jd.cr_fee] AS amt_arr
  ) arr
  CROSS JOIN UNNEST(arr.amt_arr) AS t(amt_val)
),
agg1 AS (
  SELECT
    c_customer_sk,
    t_hour,
    SUM(amt_val) AS total_amount,
    COUNT(*) AS cnt,
    AVG(sr_return_quantity) AS avg_qty
  FROM expanded
  GROUP BY c_customer_sk, t_hour
),
agg2 AS (
  SELECT
    c_customer_sk,
    total_amount,
    cnt,
    avg_qty,
    total_amount / NULLIF(cnt, 0) AS avg_amount_per_row
  FROM agg1
  WHERE cnt > 5
),
final_union AS (
  SELECT c_customer_sk, total_amount, cnt, avg_qty, avg_amount_per_row FROM agg2
  UNION
  SELECT c_customer_sk, total_amount, cnt, avg_qty, avg_amount_per_row FROM agg2
)
SELECT
  c_customer_sk,
  total_amount,
  cnt,
  avg_qty,
  avg_amount_per_row
FROM final_union
ORDER BY total_amount DESC
LIMIT 100
