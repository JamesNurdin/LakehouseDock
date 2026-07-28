WITH
  store_agg AS (
    SELECT
      d.d_date AS sales_date,
      'Store' AS sales_channel,
      SUM(ss.ss_net_paid) AS total_net_paid,
      CASE WHEN SUM(ss.ss_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS revenue_category,
      (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS avg_store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND d.d_year = 2001
      AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = ss.ss_customer_sk
          AND ws2.ws_sold_date_sk = ss.ss_sold_date_sk
      )
    GROUP BY d.d_date
  ),
  web_agg AS (
    SELECT
      d.d_date AS sales_date,
      'Web' AS sales_channel,
      SUM(ws.ws_net_paid) AS total_net_paid,
      CASE WHEN SUM(ws.ws_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS revenue_category,
      (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2) AS avg_web_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'N'
      AND d.d_year = 2001
    GROUP BY d.d_date
  ),
  combined AS (
    SELECT DISTINCT sales_date, sales_channel, total_net_paid, revenue_category
    FROM store_agg
    UNION ALL
    SELECT DISTINCT sales_date, sales_channel, total_net_paid, revenue_category
    FROM web_agg
  )
SELECT *
FROM combined
ORDER BY sales_date DESC, total_net_paid DESC
LIMIT 100
