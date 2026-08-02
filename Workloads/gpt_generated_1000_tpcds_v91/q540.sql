WITH combined AS (
  SELECT
    c.c_customer_id AS customer_id,
    s.s_store_name AS location_name,
    'Store' AS channel,
    ss.ss_net_paid AS total_sales,
    ss.ss_sold_date_sk AS sold_date_sk,
    p.p_promo_id AS promo_id
  FROM
    store_sales ss TABLESAMPLE BERNOULLI (10)
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE
    p.p_discount_active = 'N'
    AND ca.ca_state = 'CA'
    AND NOT EXISTS (
      SELECT 1
      FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
    )

  UNION ALL

  SELECT
    c.c_customer_id AS customer_id,
    w.web_name AS location_name,
    'Web' AS channel,
    ws.ws_net_paid AS total_sales,
    ws.ws_sold_date_sk AS sold_date_sk,
    p.p_promo_id AS promo_id
  FROM
    web_sales ws TABLESAMPLE BERNOULLI (10)
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    INNER JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE
    w.web_country = 'United States'
    AND ca.ca_state = 'TX'
    AND NOT EXISTS (
      SELECT 1
      FROM store_sales ss2
      WHERE ss2.ss_customer_sk = c.c_customer_sk
    )
)
SELECT
  customer_id,
  location_name,
  channel,
  total_sales,
  sold_date_sk,
  promo_id,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS channel_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100
