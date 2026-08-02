WITH excluded_keys AS (
   SELECT CONCAT(cp.cp_department, '-', CAST(cp.cp_catalog_page_number AS VARCHAR)) AS page_key
   FROM catalog_page cp
   WHERE cp.cp_type LIKE 'XX%'
),
combined_agg AS (
   SELECT
       'Catalog' AS source,
       CONCAT(cp.cp_department, '-', CAST(cp.cp_catalog_page_number AS VARCHAR)) AS page_key,
       SUBSTR(cp.cp_description, 1, 20) AS short_desc,
       SUM(cs.cs_net_profit) AS total_net_profit,
       COUNT(*) AS order_cnt,
       cp.cp_department AS category
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_date >= DATE '2002-01-01' AND d.d_date < DATE '2003-01-01'
     AND regexp_like(cp.cp_description, '\\d{3}')
     AND cp.cp_type LIKE 'PR%'
     AND ib.ib_upper_bound >= 100000
     AND NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_order_number = cs.cs_order_number
     )
   GROUP BY cp.cp_department, cp.cp_catalog_page_number, cp.cp_description
),
web_combined_agg AS (
   SELECT
       'Web' AS source,
       CONCAT(wp.wp_type, '-', CAST(wp.wp_web_page_sk AS VARCHAR)) AS page_key,
       SUBSTR(wp.wp_url, 1, 20) AS short_desc,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(*) AS order_cnt,
       wp.wp_type AS category
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_date >= DATE '2002-01-01' AND d.d_date < DATE '2003-01-01'
     AND wp.wp_url LIKE '%/promo%'
     AND regexp_like(wp.wp_url, '/promo[0-9]+')
     AND ib.ib_lower_bound <= 150000
   GROUP BY wp.wp_type, wp.wp_web_page_sk, wp.wp_url
),
unioned AS (
   SELECT * FROM combined_agg
   UNION
   SELECT * FROM web_combined_agg
),
valid_keys AS (
   SELECT page_key
   FROM unioned
   EXCEPT
   SELECT page_key
   FROM excluded_keys
)
SELECT
    u.source,
    u.page_key,
    u.short_desc,
    u.total_net_profit,
    u.order_cnt,
    ROW_NUMBER() OVER (PARTITION BY u.source ORDER BY u.total_net_profit DESC) AS rank,
    u.category
FROM unioned u
JOIN valid_keys vk ON u.page_key = vk.page_key
ORDER BY u.total_net_profit DESC
LIMIT 100
