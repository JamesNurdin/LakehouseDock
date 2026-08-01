WITH ws_agg AS (
   SELECT
      ws_sold_time_sk      AS time_sk,
      ws_web_site_sk,
      ws_bill_hdemo_sk    AS hdemo1_sk,
      ws_ship_hdemo_sk    AS hdemo2_sk,
      SUM(ws_quantity)    AS total_quantity,
      SUM(ws_net_paid)    AS total_net_paid
   FROM web_sales
   GROUP BY ws_sold_time_sk, ws_web_site_sk, ws_bill_hdemo_sk, ws_ship_hdemo_sk
),
cr_agg AS (
   SELECT
      cr_returned_time_sk AS time_sk,
      cr_refunded_hdemo_sk AS hdemo1_sk,
      cr_returning_hdemo_sk AS hdemo2_sk,
      SUM(cr_return_quantity) AS total_return_quantity,
      SUM(cr_return_amount)   AS total_return_amount
   FROM catalog_returns
   GROUP BY cr_returned_time_sk, cr_refunded_hdemo_sk, cr_returning_hdemo_sk
),
combined AS (
   SELECT
      time_sk,
      ws_web_site_sk,
      hdemo1_sk,
      hdemo2_sk,
      total_quantity,
      total_net_paid,
      CAST(NULL AS BIGINT)               AS total_return_quantity,
      CAST(NULL AS DECIMAL(7,2))         AS total_return_amount,
      'sales'   AS src
   FROM ws_agg
   UNION ALL
   SELECT
      time_sk,
      NULL AS ws_web_site_sk,
      hdemo1_sk,
      hdemo2_sk,
      CAST(NULL AS BIGINT)               AS total_quantity,
      CAST(NULL AS DECIMAL(7,2))         AS total_net_paid,
      total_return_quantity,
      total_return_amount,
      'returns' AS src
   FROM cr_agg
)
SELECT
   src,
   t.t_sub_shift,
   hd1.hd_buy_potential        AS hd1_buy_potential,
   hd2.hd_buy_potential        AS hd2_buy_potential,
   ib1.ib_lower_bound          AS hd1_lower_bound,
   ib1.ib_upper_bound          AS hd1_upper_bound,
   ib2.ib_lower_bound          AS hd2_lower_bound,
   ib2.ib_upper_bound          AS hd2_upper_bound,
   ws.web_name,
   ws.web_tax_percentage,
   SUM(COALESCE(total_quantity, 0))        AS sum_quantity,
   SUM(COALESCE(total_return_quantity, 0)) AS sum_return_quantity,
   SUM(COALESCE(total_net_paid, 0))        AS sum_net_paid,
   SUM(COALESCE(total_return_amount, 0))   AS sum_return_amount
FROM combined
JOIN time_dim t
  ON combined.time_sk = t.t_time_sk                                   -- join 1
JOIN household_demographics hd1
  ON combined.hdemo1_sk = hd1.hd_demo_sk                               -- join 2
JOIN household_demographics hd2
  ON combined.hdemo2_sk = hd2.hd_demo_sk                               -- join 3
LEFT JOIN web_site ws
  ON combined.ws_web_site_sk = ws.web_site_sk                          -- join 4
CROSS JOIN LATERAL (
   SELECT ib_lower_bound, ib_upper_bound
   FROM income_band ib
   WHERE ib.ib_income_band_sk = hd1.hd_income_band_sk
) ib1                                                                   -- join 5 (lateral)
CROSS JOIN LATERAL (
   SELECT ib_lower_bound, ib_upper_bound
   FROM income_band ib
   WHERE ib.ib_income_band_sk = hd2.hd_income_band_sk
) ib2                                                                   -- join 6 (lateral)
JOIN income_band ib_direct1
  ON ib_direct1.ib_income_band_sk = hd1.hd_income_band_sk               -- join 7
JOIN income_band ib_direct2
  ON ib_direct2.ib_income_band_sk = hd2.hd_income_band_sk               -- join 8
CROSS JOIN LATERAL (
   SELECT ib_lower_bound, ib_upper_bound
   FROM income_band ib
   WHERE ib.ib_income_band_sk = hd1.hd_income_band_sk
) ib3                                                                   -- join 9 (additional lateral)
GROUP BY
   src,
   t.t_sub_shift,
   hd1.hd_buy_potential,
   hd2.hd_buy_potential,
   ib1.ib_lower_bound,
   ib1.ib_upper_bound,
   ib2.ib_lower_bound,
   ib2.ib_upper_bound,
   ws.web_name,
   ws.web_tax_percentage
ORDER BY sum_quantity DESC
LIMIT 100
