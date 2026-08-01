WITH sub1 AS (
   SELECT
     d.d_year AS year,
     i.i_category AS category,
     i.i_item_sk AS item_sk,
     ss.ss_quantity AS store_qty,
     CAST(NULL AS integer) AS web_qty,
     ss.ss_net_profit AS store_profit,
     CAST(NULL AS decimal(7,2)) AS web_profit,
     CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_status,
     ARRAY[ss.ss_quantity, CAST(NULL AS integer)] AS qty_array,
     CAST(NULL AS bigint) AS order_number
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_category IN ('Sports', 'Books')
     AND s.s_state = 'CA'
     AND cp.cp_department = 'Electronics'
     AND cd.cd_gender = 'F'
),
sub2 AS (
   SELECT
     d.d_year AS year,
     i.i_category AS category,
     i.i_item_sk AS item_sk,
     CAST(NULL AS integer) AS store_qty,
     ws.ws_quantity AS web_qty,
     CAST(NULL AS decimal(7,2)) AS store_profit,
     ws.ws_net_profit AS web_profit,
     CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_status,
     ARRAY[CAST(NULL AS integer), ws.ws_quantity] AS qty_array,
     ws.ws_order_number AS order_number
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_site sit ON ws.ws_web_site_sk = sit.web_site_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND sm.sm_type = 'AIR'
     AND wp.wp_type = 'Content'
     AND sit.web_country = 'United States'
     AND cd.cd_education_status = 'College'
),
unioned AS (
   SELECT * FROM sub1
   UNION DISTINCT
   SELECT * FROM sub2
),
expanded AS (
   SELECT
     u.year,
     u.category,
     u.item_sk,
     u.store_qty,
     u.web_qty,
     u.store_profit,
     u.web_profit,
     u.promo_status,
     u.order_number,
     qty
   FROM unioned u
   CROSS JOIN UNNEST(u.qty_array) AS t(qty)
)
SELECT
   year,
   category,
   promo_status,
   SUM(COALESCE(store_profit, 0) + COALESCE(web_profit, 0)) AS total_net_profit,
   SUM(qty) AS total_quantity,
   RANK() OVER (PARTITION BY year ORDER BY SUM(COALESCE(store_profit, 0) + COALESCE(web_profit, 0)) DESC) AS profit_rank
FROM expanded e
WHERE EXISTS (
   SELECT 1
   FROM web_returns wr
   WHERE wr.wr_item_sk = e.item_sk
     AND wr.wr_return_quantity > 0
)
GROUP BY ROLLUP (year, category, promo_status)
ORDER BY year, profit_rank
LIMIT 100
