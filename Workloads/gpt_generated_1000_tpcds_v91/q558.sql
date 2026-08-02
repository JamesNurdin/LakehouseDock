WITH
union_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    UNION
    SELECT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
intersect_items AS (
    SELECT inv.inv_item_sk AS item_sk
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
    INTERSECT
    SELECT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
agg_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_time_sk = t.t_time_sk
        LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND i.i_current_price > 100
        AND cc.cc_division = 1
        AND hd.hd_vehicle_count >= 0
        AND i.i_item_sk IN (SELECT item_sk FROM union_items)
        AND i.i_item_sk IN (SELECT item_sk FROM intersect_items)
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name
)
SELECT
    s_store_sk,
    s_store_name,
    i_item_sk,
    i_product_name,
    total_catalog_net_paid,
    total_web_net_paid,
    total_return_loss,
    total_catalog_quantity,
    total_web_quantity,
    (total_catalog_net_paid + total_web_net_paid - total_return_loss) AS net_sales,
    ROW_NUMBER() OVER (
        PARTITION BY s_store_name
        ORDER BY (total_catalog_net_paid + total_web_net_paid - total_return_loss) DESC
    ) AS rank_within_store,
    CASE
        WHEN (total_catalog_net_paid + total_web_net_paid - total_return_loss) > 10000 THEN 'High'
        WHEN (total_catalog_net_paid + total_web_net_paid - total_return_loss) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM agg_sales
ORDER BY net_sales DESC
LIMIT 100
