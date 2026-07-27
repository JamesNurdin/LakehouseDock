WITH billed AS (
   SELECT
          income_band_sk,
          category,
          'Billed' AS metric_type,
          total_net_paid,
          order_cnt,
          avg_net_profit,
          ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_net_paid DESC) AS metric_aux
   FROM (
        SELECT
               ib.ib_income_band_sk AS income_band_sk,
               CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END AS category,
               SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
               COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
               AVG(ws.ws_net_profit) AS avg_net_profit
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ws.ws_net_paid_inc_tax > 0
        GROUP BY ib.ib_income_band_sk,
                 CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END
   ) b
),
shipped AS (
   SELECT
          income_band_sk,
          category,
          'Shipped' AS metric_type,
          total_net_paid,
          order_cnt,
          avg_net_profit,
          SUM(total_net_paid) OVER (PARTITION BY category) AS metric_aux
   FROM (
        SELECT
               ib.ib_income_band_sk AS income_band_sk,
               CASE WHEN ib.ib_lower_bound >= 80000 THEN 'Upper' ELSE 'Lower' END AS category,
               SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
               COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
               AVG(ws.ws_net_profit) AS avg_net_profit
        FROM web_sales ws
        JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ws.ws_net_profit > 0
        GROUP BY ib.ib_income_band_sk,
                 CASE WHEN ib.ib_lower_bound >= 80000 THEN 'Upper' ELSE 'Lower' END
   ) s
)
SELECT *
FROM billed
UNION ALL
SELECT *
FROM shipped
ORDER BY category, metric_type, total_net_paid DESC
LIMIT 100
