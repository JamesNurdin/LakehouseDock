WITH sales_base AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i_s
        ON cs.cs_item_sk = i_s.i_item_sk
    WHERE td_sold.t_time BETWEEN 0 AND 23
)
SELECT
    i_s.i_item_id,
    i_s.i_product_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    r_ret.r_reason_desc AS return_reason,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sa.cs_net_profit) AS total_sales_profit,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    ROW_NUMBER() OVER (PARTITION BY i_s.i_item_id ORDER BY SUM(sa.cs_net_profit) DESC) AS profit_rank
FROM sales_base sa
JOIN catalog_returns cr
    ON cr.cr_order_number = sa.cs_order_number
JOIN reason r_ret
    ON cr.cr_reason_sk = r_ret.r_reason_sk
JOIN call_center cc
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i_s
    ON sa.cs_item_sk = i_s.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i_s.i_item_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN time_dim td_ret
    ON wr.wr_returned_time_sk = td_ret.t_time_sk
JOIN item i_w
    ON wr.wr_item_sk = i_w.i_item_sk
WHERE r_ret.r_reason_id = 'AAAAAAAADBAAAAAA'
GROUP BY
    i_s.i_item_id,
    i_s.i_product_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    r_ret.r_reason_desc
ORDER BY total_sales_profit DESC
LIMIT 100
