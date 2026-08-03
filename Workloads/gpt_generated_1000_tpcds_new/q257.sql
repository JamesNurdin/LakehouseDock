WITH store_full AS (
  SELECT s.s_store_sk,
         s.s_store_id,
         s.s_store_name,
         ss.ss_sold_date_sk,
         ss.ss_quantity,
         d.d_year
  FROM store s
  FULL OUTER JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001 OR d.d_year IS NULL
),
store_agg AS (
  SELECT s_store_sk,
         s_store_id,
         s_store_name,
         d_year,
         SUM(ss_quantity) AS total_quantity,
         COUNT(*) AS trans_cnt
  FROM store_full
  GROUP BY s_store_sk, s_store_id, s_store_name, d_year
),
store_final AS (
  SELECT 'store' AS source_type,
         s_store_id   AS entity_id,
         s_store_name AS entity_name,
         d_year       AS year,
         total_quantity,
         lt.top_item_sk
  FROM store_agg sa
  CROSS JOIN LATERAL (
    SELECT ss_item_sk AS top_item_sk
    FROM store_sales ss
    WHERE ss.ss_store_sk = sa.s_store_sk
    ORDER BY ss.ss_sales_price DESC
    LIMIT 1
  ) lt
),
web_full AS (
  SELECT w.web_site_sk,
         w.web_site_id,
         w.web_name,
         ws.ws_sold_date_sk,
         ws.ws_quantity,
         d.d_year
  FROM web_site w
  FULL OUTER JOIN web_sales ws
    ON ws.ws_web_site_sk = w.web_site_sk
  LEFT JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001 OR d.d_year IS NULL
),
web_agg AS (
  SELECT web_site_sk,
         web_site_id,
         web_name,
         d_year,
         SUM(ws_quantity) AS total_quantity,
         COUNT(*) AS trans_cnt
  FROM web_full
  GROUP BY web_site_sk, web_site_id, web_name, d_year
),
web_final AS (
  SELECT 'web' AS source_type,
         web_site_id   AS entity_id,
         web_name      AS entity_name,
         d_year        AS year,
         total_quantity,
         lt.top_item_sk
  FROM web_agg wa
  CROSS JOIN LATERAL (
    SELECT ws_item_sk AS top_item_sk
    FROM web_sales ws
    WHERE ws.ws_web_site_sk = wa.web_site_sk
    ORDER BY ws.ws_sales_price DESC
    LIMIT 1
  ) lt
)
SELECT source_type,
       entity_id,
       entity_name,
       year,
       total_quantity,
       top_item_sk
FROM store_final
UNION ALL
SELECT source_type,
       entity_id,
       entity_name,
       year,
       total_quantity,
       top_item_sk
FROM web_final
LIMIT 100
