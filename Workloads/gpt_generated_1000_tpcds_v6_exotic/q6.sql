WITH sales_agg AS (
   SELECT ca.ca_state AS state,
          SUM(ss.ss_net_paid) AS metric,
          CASE WHEN SUM(ss.ss_quantity) > 1000 THEN 'HighVolume' ELSE 'LowVolume' END AS volume_category
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_current_price > 100
   GROUP BY ca.ca_state
),
web_agg AS (
   SELECT ca.ca_state AS state,
          CAST(COUNT(*) AS DECIMAL(15,2)) AS metric,
          CASE WHEN COUNT(*) > 500 THEN 'HighVolume' ELSE 'LowVolume' END AS volume_category
   FROM web_page wp
   JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE wp.wp_type = 'product'
   GROUP BY ca.ca_state
)
SELECT state, metric, volume_category
FROM sales_agg
UNION ALL
SELECT state, metric, volume_category
FROM web_agg
ORDER BY metric DESC
LIMIT 100
