WITH recent_sales AS (
    SELECT ws.*, d.d_year
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
)
SELECT
    ws.ws_web_site_sk,
    ws.ws_web_page_sk,
    ws.ws_bill_customer_sk,
    ib.ib_income_band_sk,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    CONCAT(wsite.web_name, ':', REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)) AS site_domain,
    SUBSTRING(wp.wp_type FROM 1 FOR 3) AS page_type_prefix,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM recent_sales ws
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN tpcds.customer cust
  ON ws.ws_bill_customer_sk = cust.c_customer_sk
JOIN tpcds.household_demographics hd
  ON cust.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE REGEXP_LIKE(wp.wp_url, '^https?://[^/]+/catalog')
  AND wsite.web_name LIKE '%Online%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        JOIN tpcds.date_dim d2
          ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE ws2.ws_bill_customer_sk = cust.c_customer_sk
          AND d2.d_year = 2021
          AND ws2.ws_net_paid > 0
    )
GROUP BY
    ws.ws_web_site_sk,
    ws.ws_web_page_sk,
    ws.ws_bill_customer_sk,
    ib.ib_income_band_sk,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1),
    CONCAT(wsite.web_name, ':', REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)),
    SUBSTRING(wp.wp_type FROM 1 FOR 3)
HAVING SUM(ws.ws_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
