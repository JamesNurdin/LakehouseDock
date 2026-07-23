WITH filtered_catalog_sales AS (
    SELECT cs.*
    FROM catalog_sales cs
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv_sub
        WHERE inv_sub.inv_item_sk = cs.cs_item_sk
          AND inv_sub.inv_quantity_on_hand > 0
    )
)
SELECT
    d_sold_catalog.d_year AS sales_year,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    SUM(cs.cs_net_paid) AS total_catalog_sales_net,
    SUM(ws.ws_net_paid) AS total_web_sales_net,
    SUM(ss.ss_net_paid) AS total_store_sales_net,
    SUM(cr.cr_return_amount) AS total_returns_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM filtered_catalog_sales cs
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN date_dim d_sold_catalog
    ON cs.cs_sold_date_sk = d_sold_catalog.d_date_sk
INNER JOIN date_dim d_ship_catalog
    ON cs.cs_ship_date_sk = d_ship_catalog.d_date_sk
INNER JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
INNER JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
INNER JOIN inventory inv
    ON inv.inv_date_sk = d_sold_catalog.d_date_sk
INNER JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
INNER JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_sold_date_sk = d_sold_catalog.d_date_sk
INNER JOIN date_dim d_sold_web
    ON ws.ws_sold_date_sk = d_sold_web.d_date_sk
INNER JOIN date_dim d_ship_web
    ON ws.ws_ship_date_sk = d_ship_web.d_date_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
INNER JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
INNER JOIN store_sales ss
    ON ss.ss_promo_sk = p.p_promo_sk
   AND ss.ss_sold_date_sk = d_sold_catalog.d_date_sk
GROUP BY
    d_sold_catalog.d_year,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type
ORDER BY total_catalog_sales_net DESC
LIMIT 100
