WITH
  store_agg AS (
    SELECT
      s.s_store_id,
      s.s_city,
      SUM(ss.ss_net_profit) AS store_net_profit,
      COUNT(DISTINCT c.c_customer_id) AS store_unique_customers,
      COUNT(DISTINCT i.i_brand) AS store_unique_brands,
      COUNT(DISTINCT regexp_extract(i.i_product_name, '^([^ ]+)', 1)) AS store_unique_prefixes
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)gold')
      AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
      )
    GROUP BY s.s_store_id, s.s_city
    HAVING SUM(ss.ss_net_profit) > 0
  ),
  web_agg AS (
    SELECT
      ws.ws_web_site_sk,
      w.web_name,
      SUM(ws.ws_net_profit) AS web_net_profit,
      COUNT(DISTINCT c.c_customer_id) AS web_unique_customers,
      COUNT(DISTINCT i.i_brand) AS web_unique_brands,
      COUNT(DISTINCT regexp_extract(i.i_product_name, '^([^ ]+)', 1)) AS web_unique_prefixes
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)gold')
      AND ws.ws_ship_mode_sk IN (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_code LIKE 'A%'
      )
    GROUP BY ws.ws_web_site_sk, w.web_name
    HAVING SUM(ws.ws_net_profit) > 0
  ),
  combined AS (
    SELECT
      COALESCE(sa.s_store_id, 'NO_STORE') AS store_id,
      COALESCE(sa.s_city, 'NO_CITY') AS store_city,
      COALESCE(wa.web_name, 'NO_WEB') AS web_name,
      COALESCE(sa.store_net_profit, 0) AS store_net_profit,
      COALESCE(wa.web_net_profit, 0) AS web_net_profit,
      CASE
        WHEN COALESCE(sa.store_net_profit, 0) > COALESCE(wa.web_net_profit, 0) THEN 'Store Higher'
        ELSE 'Web Higher'
      END AS profit_source,
      COALESCE(sa.store_unique_customers, 0) AS store_unique_customers,
      COALESCE(wa.web_unique_customers, 0) AS web_unique_customers,
      COALESCE(sa.store_unique_brands, 0) AS store_unique_brands,
      COALESCE(wa.web_unique_brands, 0) AS web_unique_brands,
      COALESCE(sa.store_unique_prefixes, 0) AS store_unique_prefixes,
      COALESCE(wa.web_unique_prefixes, 0) AS web_unique_prefixes,
      RANK() OVER (ORDER BY (COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0)) DESC) AS profit_rank,
      (SELECT COUNT(DISTINCT c2.c_customer_id) FROM customer c2) AS total_customers,
      (SELECT COUNT(DISTINCT i2.i_category) FROM item i2) AS total_item_categories
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
      ON sa.s_store_id = wa.web_name   -- intentional non‑matching key to keep all rows
  )
SELECT DISTINCT
  store_id,
  store_city,
  web_name,
  store_net_profit,
  web_net_profit,
  profit_source,
  store_unique_customers,
  web_unique_customers,
  store_unique_brands,
  web_unique_brands,
  store_unique_prefixes,
  web_unique_prefixes,
  profit_rank,
  total_customers,
  total_item_categories
FROM combined
WHERE (store_net_profit + web_net_profit) > (
  SELECT AVG(net_profit)
  FROM (
    SELECT ss.ss_net_profit AS net_profit FROM store_sales ss
    UNION ALL
    SELECT ws.ws_net_profit AS net_profit FROM web_sales ws
  ) t
)
ORDER BY profit_rank
LIMIT 100
