WITH base AS (
  SELECT
    cc.cc_name,
    cc.cc_state,
    w.w_city,
    w.w_state,
    t.t_hour,
    cd_ref.cd_gender,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    cr.cr_order_number,
    CASE
      WHEN cr.cr_return_amount > 100 THEN 'High'
      WHEN cr.cr_return_amount > 0 THEN 'Low'
      ELSE 'Zero'
    END AS amount_category
  FROM catalog_returns cr
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
  JOIN customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
  JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  WHERE cc.cc_country = 'United States'
    AND w.w_country = 'United States'
    AND t.t_hour BETWEEN 9 AND 18
),
agg AS (
  SELECT
    cc_name,
    w_city,
    amount_category,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_quantity,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    AVG(cr_return_amount) AS avg_return_amount
  FROM base
  GROUP BY ROLLUP (cc_name, w_city, amount_category)
  HAVING SUM(cr_return_amount) > 0
)
SELECT
  cc_name,
  w_city,
  amount_category,
  total_return_amount,
  total_quantity,
  distinct_orders,
  avg_return_amount,
  SUM(total_return_amount) OVER (PARTITION BY w_city) AS city_total_return,
  (SELECT MAX(total_return_amount) FROM agg) AS max_total_return,
  CASE
    WHEN SUM(total_return_amount) OVER (PARTITION BY w_city) > 10000 THEN 'Big City'
    ELSE 'Small City'
  END AS city_size_flag
FROM agg
WHERE (cc_name IS NOT NULL OR w_city IS NOT NULL)
ORDER BY w_city ASC, total_return_amount DESC
LIMIT 100
