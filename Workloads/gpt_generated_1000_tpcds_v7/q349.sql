WITH sales_agg AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        sm.sm_code,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
        SUM(COALESCE(i.i_current_price, 0) * COALESCE(inv.inv_quantity_on_hand, 0)) AS inventory_value,
        SUM(CASE WHEN wp.wp_type IS NOT NULL THEN 1 ELSE 0 END) AS web_page_cnt
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                                 AND inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = i.i_item_sk
                                      AND cr.cr_returned_date_sk = d.d_date_sk
                                      AND cr.cr_returned_time_sk = t.t_time_sk
                                      AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                      AND cr.cr_refunded_addr_sk = ca.ca_address_sk
                                      AND cr.cr_call_center_sk = cc.cc_call_center_sk
                                      AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
                                      AND cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                    AND sr.sr_customer_sk = c.c_customer_sk
                                    AND sr.sr_addr_sk = ca.ca_address_sk
                                    AND sr.sr_returned_date_sk = d.d_date_sk
                                    AND sr.sr_return_time_sk = t.t_time_sk
        LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                                    AND wr.wr_refunded_customer_sk = c.c_customer_sk
                                    AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                                    AND wr.wr_returned_date_sk = d.d_date_sk
                                    AND wr.wr_returned_time_sk = t.t_time_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND w.w_warehouse_sq_ft > 200000
        AND sm.sm_code = 'AIR'
        AND p.p_discount_active = 'Y'
        AND i.i_color = 'Red'
    GROUP BY
        d.d_year,
        w.w_warehouse_name,
        sm.sm_code
)
SELECT
    d_year,
    w_warehouse_name,
    sm_code,
    total_net_paid,
    total_net_profit,
    order_cnt,
    total_catalog_return_amount,
    total_store_return_amount,
    total_web_return_amount,
    inventory_value,
    web_page_cnt,
    total_net_profit / NULLIF(order_cnt, 0) AS avg_profit_per_order
FROM sales_agg
WHERE total_net_profit > 100000
ORDER BY total_net_profit DESC
LIMIT 100
