WITH
  filtered_customers AS (
    SELECT *
    FROM customer
    WHERE c_birth_country IN ('ZIMBABWE', 'COSTA RICA')
      AND c_current_hdemo_sk IN (
        SELECT DISTINCT c_current_hdemo_sk
        FROM customer
        WHERE c_current_hdemo_sk > 1000
      )
  ),
  store_sales_enriched AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_customer_sk,
      ss.ss_item_sk,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d.d_date,
      d.d_year,
      d.d_quarter_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN filtered_customers c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_quantity > 5
  ),
  web_sales_enriched AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_item_sk,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_web_site_sk,
      d.d_date,
      d.d_year,
      d.d_quarter_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN filtered_customers c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_web_page_sk IN (
      SELECT DISTINCT ss_item_sk
      FROM store_sales
      WHERE ss_quantity > 5
    )
  )
SELECT
  COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk) AS customer_sk,
  COALESCE(c.c_customer_id, '') AS customer_id,
  COALESCE(ss.d_date, ws.d_date) AS sale_date,
  COALESCE(ss.d_year, ws.d_year) AS sale_year,
  COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) AS total_net_paid,
  COUNT(DISTINCT ss.ss_item_sk) OVER (PARTITION BY COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)) AS distinct_store_items,
  COUNT(DISTINCT ws.ws_item_sk) OVER (PARTITION BY COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)) AS distinct_web_items,
  CASE WHEN COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  ROW_NUMBER() OVER (
    PARTITION BY COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)
    ORDER BY COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) DESC
  ) AS purchase_rank,
  (
    SELECT SUM(ss2.ss_net_paid)
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)
  ) AS customer_total_store_spent,
  web_site.web_name
FROM store_sales_enriched ss
FULL OUTER JOIN web_sales_enriched ws
  ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN filtered_customers c
  ON c.c_customer_sk = COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)
LEFT JOIN web_site
  ON ws.ws_web_site_sk = web_site.web_site_sk
WHERE COALESCE(ss.d_year, ws.d_year) BETWEEN 1999 AND 2001
  AND (COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) > 100
  AND web_site.web_class = 'News'
ORDER BY total_net_paid DESC
LIMIT 100
