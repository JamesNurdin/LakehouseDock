WITH returns_only AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT cs_order_number
    FROM catalog_sales
)
SELECT
    i.i_category AS item_category,
    w.w_state AS warehouse_state,
    r.r_reason_desc AS return_reason,
    COUNT(DISTINCT cr.cr_order_number) AS num_catalog_return_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High'
        ELSE 'Moderate'
    END AS loss_level,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
    COUNT(DISTINCT wr.wr_order_number) AS num_web_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_sales_orders
FROM catalog_returns cr
JOIN returns_only ro ON cr.cr_order_number = ro.cr_order_number
JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE ib.ib_upper_bound IS NOT NULL
GROUP BY i.i_category, w.w_state, r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
