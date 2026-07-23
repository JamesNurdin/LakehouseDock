WITH sales_metrics AS (
  SELECT
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(ss.ss_ext_sales_price) AS total_amount,
    'sales' AS source
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE cd.cd_credit_rating = 'Good'
    AND hd.hd_vehicle_count >= 1
    AND t.t_shift = 'Evening'
  GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_vehicle_count
),
returns_metrics AS (
  SELECT
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(sr.sr_refunded_cash) AS total_amount,
    'returns' AS source
  FROM store_returns sr
  JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                      AND sr.sr_item_sk = ss.ss_item_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE cd.cd_credit_rating = 'Good'
    AND hd.hd_vehicle_count >= 1
    AND t.t_shift = 'Morning'
  GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_vehicle_count
)
SELECT c_customer_id, cd_gender, hd_vehicle_count, total_amount, source
FROM sales_metrics
UNION ALL
SELECT c_customer_id, cd_gender, hd_vehicle_count, total_amount, source
FROM returns_metrics
LIMIT 100
