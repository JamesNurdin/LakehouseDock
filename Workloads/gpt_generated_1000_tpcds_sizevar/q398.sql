WITH ws_filtered AS (
   SELECT
       ws.ws_order_number,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       ws.ws_list_price,
       ws.ws_quantity,
       ws.ws_sold_date_sk,
       ws.ws_web_site_sk,
       ws.ws_ship_mode_sk,
       ws.ws_warehouse_sk,
       CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
       regexp_extract(ws_site.web_name, '(\\d+)', 1) AS site_number_extracted,
       ws_site.web_name
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   WHERE d.d_year = 2002
     AND ws_site.web_name LIKE '%Shop%'
     AND regexp_like(ws_site.web_name, '^.*[A-Z]{2}.*$')
),
ws_agg AS (
   SELECT
       ws_filtered.ws_order_number AS order_number,
       SUM(ws_filtered.ws_ext_sales_price) AS total_sales,
       SUM(ws_filtered.ws_net_profit) AS total_profit,
       MAX(ws_filtered.profit_flag) AS overall_flag,
       MAX(ws_filtered.site_number_extracted) AS site_number_extracted
   FROM ws_filtered
   GROUP BY ws_filtered.ws_order_number
),
cr_keys AS (
   SELECT DISTINCT cr.cr_order_number AS order_number
   FROM tpcds.catalog_returns cr
   JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cc.cc_name LIKE '%Center%'
     AND regexp_extract(cc.cc_name, '([A-Za-z]+)', 1) = 'Center'
)
SELECT
   ws_agg.order_number,
   ws_agg.total_sales,
   ws_agg.total_profit,
   ws_agg.overall_flag,
   ws_agg.site_number_extracted
FROM ws_agg
EXCEPT
SELECT
   cr_keys.order_number,
   CAST(NULL AS double) AS total_sales,
   CAST(NULL AS double) AS total_profit,
   CAST(NULL AS varchar) AS overall_flag,
   CAST(NULL AS varchar) AS site_number_extracted
FROM cr_keys
LIMIT 100
