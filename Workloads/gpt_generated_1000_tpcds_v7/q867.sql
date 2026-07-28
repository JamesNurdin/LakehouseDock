WITH sales_join AS (
   SELECT
       cs.cs_quantity,
       cs.cs_net_profit,
       cc.cc_call_center_id,
       cc.cc_state,
       cp.cp_catalog_page_id,
       cp.cp_type,
       d_sold.d_date,
       d_sold.d_year,
       d_open.d_year AS open_year,
       wp.wp_image_count
   FROM catalog_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d_open
     ON cc.cc_open_date_sk = d_open.d_date_sk
   JOIN web_page wp
     ON wp.wp_creation_date_sk = d_open.d_date_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE
     d_sold.d_date >= DATE '2001-01-01'
     AND d_sold.d_date < DATE '2002-01-01'
     AND cc.cc_state = 'CA'
     AND cp.cp_type = 'C'
     AND wp.wp_image_count >= 5
     AND cs.cs_quantity > 10
),
agg_per_page AS (
   SELECT
     cc_call_center_id,
     cp_catalog_page_id,
     SUM(cs_net_profit) AS total_profit,
     SUM(cs_quantity) AS total_quantity
   FROM sales_join
   GROUP BY cc_call_center_id, cp_catalog_page_id
)
SELECT
  cc_call_center_id,
  AVG(total_profit) AS avg_profit_per_page,
  SUM(total_quantity) AS total_quantity_across_pages
FROM agg_per_page
GROUP BY cc_call_center_id
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit_per_page DESC
LIMIT 10
