/* Goal: Analyze return behavior by reason and return amount, combining catalog, store, and web sales data, while applying realistic filters and sampling. */
WITH
  -- First branch of the UNION with one set of filter values
  q1 AS (
    SELECT
      CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'ZeroOrNeg' END AS return_category,
      r.r_reason_desc AS reason_desc,
      cr.cr_return_amount AS return_amount,
      ws.ws_sales_price AS sales_price,
      ws.ws_quantity AS quantity
    FROM
      store_returns sr
      JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
      JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
      JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
      JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
      JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
      JOIN catalog_returns cr ON cr.cr_returned_time_sk = t_sr.t_time_sk
      JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN web_sales ws TABLESAMPLE BERNOULLI (10) ON ws.ws_sold_time_sk = t_sr.t_time_sk
    WHERE
      c_sr.c_preferred_cust_flag = 'Y'
      AND c_sr.c_birth_country = 'MEXICO'
      AND r.r_reason_id = 'AAAAAAAABAAAAAA'
      AND t_sr.t_am_pm = 'PM'
      AND sm.sm_carrier = 'UPS'
      AND ws.ws_quantity > 5
  ),
  -- Second branch of the UNION with a different set of filter values
  q2 AS (
    SELECT
      CASE WHEN cr.cr_return_amount > 0 THEN 'Positive' ELSE 'ZeroOrNeg' END AS return_category,
      r.r_reason_desc AS reason_desc,
      cr.cr_return_amount AS return_amount,
      ws.ws_sales_price AS sales_price,
      ws.ws_quantity AS quantity
    FROM
      store_returns sr
      JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
      JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
      JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
      JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
      JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
      JOIN catalog_returns cr ON cr.cr_returned_time_sk = t_sr.t_time_sk
      JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN web_sales ws TABLESAMPLE BERNOULLI (10) ON ws.ws_sold_time_sk = t_sr.t_time_sk
    WHERE
      c_sr.c_preferred_cust_flag = 'Y'
      AND c_sr.c_birth_country = 'KOREA'
      AND r.r_reason_id = 'AAAAAAAEBAAAAAA'
      AND t_sr.t_am_pm = 'AM'
      AND sm.sm_carrier = 'FedEx'
      AND ws.ws_quantity > 10
  )
SELECT
  return_category,
  reason_desc,
  COUNT(*) AS cnt,
  SUM(return_amount) AS total_return_amount,
  AVG(sales_price) AS avg_sales_price,
  MIN(quantity) AS min_quantity,
  MAX(quantity) AS max_quantity
FROM (
  SELECT * FROM q1
  UNION DISTINCT
  SELECT * FROM q2
) u
GROUP BY
  return_category,
  reason_desc
ORDER BY
  total_return_amount DESC
LIMIT 100
