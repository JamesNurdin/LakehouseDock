WITH distinct_items AS (
  SELECT DISTINCT i.i_item_sk,
                  i.i_category,
                  i.i_product_name,
                  i.i_item_desc
  FROM tpcds.item i
  WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
)
SELECT
  d.d_year,
  d.d_month_seq,
  di.i_category,
  di.i_product_name,
  CONCAT(di.i_category, '-', di.i_product_name) AS cat_prod,
  SUBSTR(di.i_item_desc, 1, 5) AS desc_prefix,
  REGEXP_EXTRACT(di.i_item_desc, '([0-9]{2})', 1) AS numeric_suffix,
  SUM(ws.ws_net_paid) AS total_net_paid,
  CASE WHEN SUM(ws.ws_net_paid) > 1000000 THEN 'High' ELSE 'Normal' END AS sales_level
FROM tpcds.web_sales ws
JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN distinct_items di ON ws.ws_item_sk = di.i_item_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_url LIKE '%example%'
GROUP BY
  d.d_year,
  d.d_month_seq,
  di.i_category,
  di.i_product_name,
  di.i_item_desc
ORDER BY total_net_paid DESC
LIMIT 100
