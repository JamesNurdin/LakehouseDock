WITH
  sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  filtered_store_sales AS (
    SELECT ss.*
    FROM sampled_store_sales ss
    WHERE ss.ss_store_sk IN (
      SELECT s_store_sk
      FROM store
      WHERE regexp_like(s_store_name, 'Market')
    )
  ),
  store_key_set AS (
    SELECT DISTINCT ss.ss_store_sk AS key_id
    FROM filtered_store_sales ss
  ),
  web_key_set AS (
    SELECT DISTINCT ws.ws_web_site_sk AS key_id
    FROM web_sales ws
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE we.web_city LIKE 'San%'
  ),
  common_keys AS (
    SELECT key_id FROM store_key_set
    INTERSECT
    SELECT key_id FROM web_key_set
  ),
  union_sales AS (
    SELECT
      ss.ss_store_sk AS location_id,
      ss.ss_ext_sales_price AS sales,
      ss.ss_net_profit AS profit,
      concat('Store_', cast(ss.ss_store_sk AS varchar)) AS label,
      CAST(NULL AS varchar) AS city_prefix
    FROM filtered_store_sales ss
    WHERE ss.ss_store_sk IN (SELECT key_id FROM common_keys)

    UNION DISTINCT

    SELECT
      ws.ws_web_site_sk AS location_id,
      ws.ws_ext_sales_price AS sales,
      ws.ws_net_profit AS profit,
      concat('WebSite_', cast(ws.ws_web_site_sk AS varchar)) AS label,
      substring(we.web_city, 1, 3) AS city_prefix
    FROM web_sales ws
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE ws.ws_web_site_sk IN (SELECT key_id FROM common_keys)
      AND we.web_street_name LIKE '%Main%'
      AND regexp_extract(we.web_street_name, '(\\w+)') = 'Main'
  )
SELECT
  us.location_id,
  us.label,
  us.city_prefix,
  sum(us.sales) AS total_sales,
  sum(us.profit) AS total_profit,
  count(*) AS txn_count
FROM union_sales us
GROUP BY us.location_id, us.label, us.city_prefix
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
