WITH hd_income AS (
    SELECT hd.hd_demo_sk,
           CASE
               WHEN ib.ib_upper_bound > 80000 THEN 'HIGH'
               WHEN ib.ib_upper_bound BETWEEN 50000 AND 80000 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS income_level
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT month,
       sales,
       profit,
       order_cnt,
       avg_month_sales,
       CASE WHEN profit > 10000 THEN 'HIGH_PROFIT' ELSE 'LOW_PROFIT' END AS profit_category
FROM (
    SELECT d.d_month_seq AS month,
           SUM(cs.cs_ext_sales_price) AS sales,
           SUM(cs.cs_net_profit) AS profit,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
           (
               SELECT AVG(cs_sub.cs_ext_sales_price)
               FROM catalog_sales cs_sub
               JOIN date_dim d_sub ON cs_sub.cs_sold_date_sk = d_sub.d_date_sk
               WHERE d_sub.d_month_seq = d.d_month_seq
           ) AS avg_month_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN hd_income hdi ON cs.cs_bill_hdemo_sk = hdi.hd_demo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1 FROM store s WHERE s.s_closed_date_sk = d.d_date_sk
      )
    GROUP BY d.d_month_seq
    HAVING SUM(cs.cs_ext_sales_price) > 50000
) cat
UNION
SELECT month,
       sales,
       profit,
       order_cnt,
       avg_month_sales,
       CASE WHEN profit > 10000 THEN 'HIGH_PROFIT' ELSE 'LOW_PROFIT' END AS profit_category
FROM (
    SELECT d.d_month_seq AS month,
           SUM(ws.ws_ext_sales_price) AS sales,
           SUM(ws.ws_net_profit) AS profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
           (
               SELECT AVG(ws_sub.ws_ext_sales_price)
               FROM web_sales ws_sub
               JOIN date_dim d_sub ON ws_sub.ws_sold_date_sk = d_sub.d_date_sk
               WHERE d_sub.d_month_seq = d.d_month_seq
           ) AS avg_month_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN hd_income hdi ON ws.ws_bill_hdemo_sk = hdi.hd_demo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1 FROM store s WHERE s.s_closed_date_sk = d.d_date_sk
      )
    GROUP BY d.d_month_seq
    HAVING SUM(ws.ws_ext_sales_price) > 50000
) web
ORDER BY month, sales DESC
LIMIT 100
