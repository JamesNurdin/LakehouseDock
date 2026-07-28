WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_profit)                AS total_profit,
        COUNT(cr.cr_return_quantity)          AS total_return_qty,
        SUM(cs.cs_quantity)                   AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
       AND ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN web_site we
        ON we.web_open_date_sk = d_sold.d_date_sk
    WHERE
        s.s_market_manager IN ('David Lamontagne', 'Edward Stone')
        AND hd_bill.hd_vehicle_count >= 1
        AND sm.sm_contract = 'HVDFCcQ'
        AND i.i_brand = 'BrandX'
        AND d_sold.d_year = 2001
        AND cs.cs_quantity > 5
        AND cc.cc_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_product_name
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    i_item_id,
    i_product_name,
    total_profit,
    total_return_qty,
    CASE WHEN total_quantity > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
    RANK() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS profit_rank_state
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
