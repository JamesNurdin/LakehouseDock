WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(ss.ss_quantity) AS store_sales_quantity
    FROM store_sales ss
    GROUP BY
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk
)
SELECT
    s.s_store_id,
    i.i_item_id,
    p.p_promo_id,
    COALESCE(reason_sr.r_reason_desc, reason_cr.r_reason_desc, reason_wr.r_reason_desc, 'N/A') AS reason_desc,
    td_ss.t_hour AS sale_hour,
    SUM(ssa.store_sales_net_paid) AS total_store_sales_net_paid,
    SUM(ssa.store_sales_net_profit) AS total_store_sales_net_profit,
    SUM(ssa.store_sales_quantity) AS total_store_sales_quantity,
    SUM(cs.cs_net_paid) AS total_catalog_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_sales_net_profit,
    SUM(cs.cs_quantity) AS total_catalog_sales_quantity,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_return_net_loss,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_return_net_loss,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_return_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT ssa.store_sales_quantity) AS distinct_store_sales_rows,
    MIN(td_wr.t_hour) AS min_return_hour,
    MAX(td_wr.t_hour) AS max_return_hour
FROM store_sales_agg ssa
JOIN store s
    ON ssa.ss_store_sk = s.s_store_sk
JOIN item i
    ON ssa.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ssa.ss_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN time_dim td_ss
    ON ssa.ss_sold_time_sk = td_ss.t_time_sk
LEFT JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason reason_sr
    ON sr.sr_reason_sk = reason_sr.r_reason_sk
LEFT JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
    AND c.c_birth_country = 'SWITZERLAND'
    AND c.c_current_hdemo_sk = 3986
LEFT JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_order_number = cs.cs_order_number
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN time_dim td_cr
    ON cr.cr_returned_time_sk = td_cr.t_time_sk
LEFT JOIN reason reason_cr
    ON cr.cr_reason_sk = reason_cr.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_return_ship_cost > 1000.00
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
LEFT JOIN reason reason_wr
    ON wr.wr_reason_sk = reason_wr.r_reason_sk
WHERE p.p_channel_dmail = 'Y'
GROUP BY
    s.s_store_id,
    i.i_item_id,
    p.p_promo_id,
    COALESCE(reason_sr.r_reason_desc, reason_cr.r_reason_desc, reason_wr.r_reason_desc, 'N/A'),
    td_ss.t_hour
ORDER BY total_store_sales_net_paid DESC
LIMIT 100
