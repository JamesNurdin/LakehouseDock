WITH orders_no_return AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
),
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        i1.i_category,
        w.w_state,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS sale_type,
        cr.cr_return_amount,
        r.r_reason_desc,
        c_ref.c_customer_id,
        ca.ca_city,
        hd.hd_vehicle_count,
        inv.inv_quantity_on_hand,
        ss.ss_quantity AS ss_quantity,
        ws.ws_sales_price,
        wp.wp_type,
        ROW_NUMBER() OVER (PARTITION BY i1.i_category ORDER BY cs.cs_sold_date_sk) AS row_num
    FROM catalog_sales cs
    JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i1.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i1.i_item_sk
    LEFT JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk  -- second alias of ITEM
    LEFT JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    LEFT JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i1.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM orders_no_return)
)
SELECT
    i_category,
    w_state,
    sale_type,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(hd_vehicle_count) AS avg_vehicle_count,
    MAX(inv_quantity_on_hand) AS max_inventory,
    LAG(SUM(cs_ext_sales_price)) OVER (PARTITION BY i_category ORDER BY sale_type) AS prev_category_sales
FROM base
GROUP BY i_category, w_state, sale_type
ORDER BY total_sales DESC
LIMIT 100
