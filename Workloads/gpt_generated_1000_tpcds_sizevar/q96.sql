WITH web_sales_agg AS (
   SELECT
       d.d_year AS year,
       CASE WHEN sm.sm_type = 'AIR' THEN 'AIR' ELSE 'OTHER' END AS ship_mode_type,
       'Web Sales' AS metric_type,
       SUM(ws.ws_ext_sales_price) AS total_amount
   FROM tpcds.web_sales ws
   JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, sm.sm_type
),
catalog_returns_agg AS (
   SELECT
       d.d_year AS year,
       CASE WHEN sm.sm_type = 'AIR' THEN 'AIR' ELSE 'OTHER' END AS ship_mode_type,
       'Catalog Returns' AS metric_type,
       SUM(cr.cr_return_amount) AS total_amount
   FROM tpcds.catalog_returns cr
   JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, sm.sm_type
)
SELECT year, ship_mode_type, metric_type, total_amount
FROM web_sales_agg
UNION
SELECT year, ship_mode_type, metric_type, total_amount
FROM catalog_returns_agg
LIMIT 100
