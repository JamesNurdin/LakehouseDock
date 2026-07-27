WITH catalog_agg AS (
   SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      concat(i.i_brand, '-', i.i_color) AS brand_color,
      SUM(cs.cs_net_paid) AS total_sales,
      'Catalog' AS channel
   FROM tpcds.catalog_sales cs
   JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '(?i)large')
     AND i.i_size LIKE 'extra %'
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_brand, i.i_color
),
web_agg AS (
   SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      concat(i.i_brand, '-', i.i_color) AS brand_color,
      SUM(ws.ws_net_paid) AS total_sales,
      'Web' AS channel
   FROM tpcds.web_sales ws
   JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
   JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_url LIKE '%promo%'
     AND regexp_extract(wp.wp_url, 'promo([0-9]+)', 1) IS NOT NULL
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_brand, i.i_color
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
