WITH inv_agg AS (
   SELECT inv_date_sk,
          inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory TABLESAMPLE BERNOULLI (10)
   GROUP BY CUBE (inv_date_sk, inv_item_sk, inv_warehouse_sk)
)
SELECT
   d_sold.d_year                         AS year,
   s.s_store_name                        AS store_name,
   cc.cc_name                            AS call_center_name,
   wp.wp_type                            AS page_type,
   SUM(ss.ss_net_paid)                  AS total_net_paid,
   SUM(i.total_qty)                      AS total_inventory_qty,
   ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS rnk
FROM store_sales ss
FULL OUTER JOIN store s
   ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
   ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_extra
   ON ss.ss_sold_date_sk = d_extra.d_date_sk
JOIN date_dim d_store_closed
   ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
   ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
   ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_page wp
   ON wp.wp_creation_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_wp_access
   ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN inv_agg i
   ON i.inv_date_sk = d_sold.d_date_sk
WHERE EXISTS (
   SELECT 1 FROM call_center cc2
   WHERE cc2.cc_market_manager = cc.cc_market_manager
     AND cc2.cc_closed_date_sk = cc.cc_closed_date_sk
)
GROUP BY CUBE (d_sold.d_year, s.s_store_name, cc.cc_name, wp.wp_type)
HAVING SUM(ss.ss_net_paid) > 1000

UNION DISTINCT

SELECT
   d_sold2.d_year                         AS year,
   s2.s_store_name                        AS store_name,
   cc2.cc_name                            AS call_center_name,
   wp2.wp_type                            AS page_type,
   SUM(ss2.ss_net_paid)                  AS total_net_paid,
   SUM(i2.total_qty)                      AS total_inventory_qty,
   ROW_NUMBER() OVER (PARTITION BY d_sold2.d_year ORDER BY SUM(ss2.ss_net_paid) DESC) AS rnk
FROM store_sales ss2
FULL OUTER JOIN store s2
   ON ss2.ss_store_sk = s2.s_store_sk
JOIN date_dim d_sold2
   ON ss2.ss_sold_date_sk = d_sold2.d_date_sk
JOIN date_dim d_extra2
   ON ss2.ss_sold_date_sk = d_extra2.d_date_sk
JOIN date_dim d_store_closed2
   ON s2.s_closed_date_sk = d_store_closed2.d_date_sk
JOIN call_center cc2
   ON cc2.cc_closed_date_sk = d_store_closed2.d_date_sk
JOIN date_dim d_cc_open2
   ON cc2.cc_open_date_sk = d_cc_open2.d_date_sk
JOIN web_page wp2
   ON wp2.wp_creation_date_sk = d_cc_open2.d_date_sk
JOIN date_dim d_wp_access2
   ON wp2.wp_access_date_sk = d_wp_access2.d_date_sk
JOIN inv_agg i2
   ON i2.inv_date_sk = d_sold2.d_date_sk
WHERE EXISTS (
   SELECT 1 FROM call_center c3
   WHERE c3.cc_market_manager = cc2.cc_market_manager
     AND c3.cc_closed_date_sk = cc2.cc_closed_date_sk
)
GROUP BY CUBE (d_sold2.d_year, s2.s_store_name, cc2.cc_name, wp2.wp_type)
HAVING SUM(ss2.ss_net_paid) > 2000

ORDER BY year DESC, total_net_paid DESC
LIMIT 100
