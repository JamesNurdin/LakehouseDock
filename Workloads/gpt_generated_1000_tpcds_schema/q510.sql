WITH first_part AS (
   SELECT d.d_year AS year,
          concat(substr(wp.wp_url, 1, 10), '_') AS label,
          sum(ws.ws_ext_sales_price) AS metric,
          CASE WHEN sum(ws.ws_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS category,
          CAST((SELECT count(*)
                FROM inventory inv
                JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
                WHERE d2.d_year = d.d_year) AS decimal(15,2)) AS inventory_metric
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
   WHERE regexp_like(wp.wp_url, '^https?://.*product.*$')
     AND wp.wp_type LIKE 'C%'
     AND EXISTS (SELECT 1 FROM call_center cc WHERE cc.cc_state = 'CA' AND cc.cc_company = wsi.web_company_id)
   GROUP BY d.d_year, concat(substr(wp.wp_url, 1, 10), '_')
),
second_part AS (
   SELECT d.d_year AS year,
          concat(substring(cc.cc_name, 1, 10), '_') AS label,
          sum(cr.cr_return_amount) AS metric,
          CASE WHEN sum(cr.cr_return_amount) > 50000 THEN 'High' ELSE 'Low' END AS category,
          CAST((SELECT sum(inv.inv_quantity_on_hand)
                FROM inventory inv
                JOIN date_dim d3 ON inv.inv_date_sk = d3.d_date_sk
                WHERE d3.d_year = d.d_year) AS decimal(15,2)) AS inventory_metric
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE regexp_extract(cc.cc_name, '(\\w+)', 1) LIKE 'A%'
     AND cc.cc_city LIKE '%ville%'
   GROUP BY d.d_year, concat(substring(cc.cc_name, 1, 10), '_')
)
SELECT year,
       label,
       metric,
       category,
       inventory_metric,
       row_number() OVER (ORDER BY metric DESC) AS global_rn
FROM (
   SELECT * FROM first_part
   UNION DISTINCT
   SELECT * FROM second_part
) AS u
ORDER BY metric DESC
LIMIT 100
