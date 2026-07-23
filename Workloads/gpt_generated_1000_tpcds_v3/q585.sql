/*
  Goal: Calculate total net sales and returns by item and warehouse for high‑value items sold during business hours, rank items by sales within each warehouse, and include inventory context.
*/
WITH agg_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        w.w_warehouse_name,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_catalog_sales,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_sales,
        SUM(cr.cr_net_loss) AS total_catalog_returns,
        SUM(wr.wr_net_loss) AS total_web_returns,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        MIN(t.t_hour) AS min_hour,
        MAX(t.t_hour) AS max_hour
    FROM
        catalog_sales cs
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
        LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_addr_sk = ca.ca_address_sk
            AND ws.ws_warehouse_sk = w.w_warehouse_sk
            AND ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
            AND wp.wp_customer_sk = c.c_customer_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = i.i_item_sk
            AND wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE
        inv.inv_quantity_on_hand > 500
        AND inv.inv_warehouse_sk = 1
        AND ca.ca_location_type = 'apartment'
        AND ca.ca_street_type = 'Blvd'
        AND w.w_street_type = 'Ave'
        AND t.t_hour BETWEEN 9 AND 17
        AND p.p_discount_active = 'Y'
        AND i.i_brand = 'BrandA'
        AND i.i_category = 'Category1'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        w.w_warehouse_name
    HAVING
        SUM(cs.cs_net_paid_inc_ship_tax) + SUM(ws.ws_net_paid_inc_ship_tax) > 10000
)
SELECT
    a.i_item_id,
    a.i_item_desc,
    a.w_warehouse_name,
    (a.total_catalog_sales + a.total_web_sales) AS total_sales,
    (a.total_catalog_returns + a.total_web_returns) AS total_returns,
    (a.total_catalog_quantity + a.total_web_quantity) AS total_quantity,
    a.distinct_customers,
    a.min_hour,
    a.max_hour,
    (
        SELECT AVG(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = a.i_item_sk
    ) AS avg_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_name ORDER BY (a.total_catalog_sales + a.total_web_sales) DESC) AS item_rank
FROM agg_sales a
ORDER BY total_sales DESC, item_rank
LIMIT 100
