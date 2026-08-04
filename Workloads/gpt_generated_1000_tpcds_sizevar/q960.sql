WITH
  store_data AS (
    SELECT
      ca.ca_state,
      ca.ca_city,
      ss.ss_net_paid,
      ss.ss_ext_tax,
      ca.ca_zip,
      ss.ss_customer_sk
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^[A-Z][a-z]+')
  ),
  web_data AS (
    SELECT
      ca.ca_state,
      ca.ca_city,
      ws.ws_net_paid,
      ws.ws_ext_tax,
      ca.ca_zip,
      ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%/home%'
      AND regexp_like(wp.wp_url, 'home[0-9]+')
  ),
  common_customers AS (
    SELECT ss_customer_sk AS customer_sk FROM store_sales
    INTERSECT
    SELECT ws_bill_customer_sk FROM web_sales
  ),
  store_with_lateral AS (
    SELECT
      sd.ca_state,
      sd.ca_city,
      sd.ss_net_paid,
      sd.ss_ext_tax,
      zip_info.zip_prefix,
      sd.ss_customer_sk
    FROM store_data sd
    CROSS JOIN LATERAL (
      SELECT regexp_extract(sd.ca_zip, '(\\d{3})', 1) AS zip_prefix
    ) AS zip_info
    WHERE sd.ss_customer_sk IN (SELECT customer_sk FROM common_customers)
  ),
  web_with_lateral AS (
    SELECT
      wd.ca_state,
      wd.ca_city,
      wd.ws_net_paid,
      wd.ws_ext_tax,
      zip_info.zip_prefix,
      wd.ws_bill_customer_sk
    FROM web_data wd
    CROSS JOIN LATERAL (
      SELECT regexp_extract(wd.ca_zip, '(\\d{3})', 1) AS zip_prefix
    ) AS zip_info
    WHERE wd.ws_bill_customer_sk IN (SELECT customer_sk FROM common_customers)
  ),
  union_all_sales AS (
    SELECT
      ca_state,
      ca_city,
      zip_prefix,
      ss_net_paid AS net_paid,
      ss_ext_tax AS ext_tax,
      'store' AS channel
    FROM store_with_lateral
    UNION DISTINCT
    SELECT
      ca_state,
      ca_city,
      zip_prefix,
      ws_net_paid AS net_paid,
      ws_ext_tax AS ext_tax,
      'web' AS channel
    FROM web_with_lateral
  )
SELECT
  ca_state,
  ca_city,
  zip_prefix,
  channel,
  COUNT(*) AS sales_count,
  SUM(net_paid) AS total_net_paid,
  SUM(ext_tax) AS total_tax,
  (SELECT AVG(net_paid) FROM union_all_sales) AS avg_net_paid_all
FROM union_all_sales
GROUP BY ROLLUP (ca_state, ca_city, zip_prefix, channel)
ORDER BY ca_state NULLS LAST,
         ca_city NULLS LAST,
         zip_prefix NULLS LAST,
         channel
LIMIT 100
