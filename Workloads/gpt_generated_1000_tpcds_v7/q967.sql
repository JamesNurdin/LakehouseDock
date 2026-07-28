WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
)
SELECT
    cp.cp_department,
    p.p_channel_dmail,
    td_sold.t_shift,
    SUM(base.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_refunded_cash, 0)) AS total_catalog_refunded_cash,
    SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_store_refunded_cash,
    COUNT(DISTINCT base.cs_order_number) AS distinct_orders
FROM base_sales base
-- join the time of the sale
JOIN time_dim td_sold
    ON base.cs_sold_time_sk = td_sold.t_time_sk
-- catalog page information
JOIN catalog_page cp
    ON base.cs_catalog_page_sk = cp.cp_catalog_page_sk
-- warehouse that shipped the item
JOIN warehouse w
    ON base.cs_warehouse_sk = w.w_warehouse_sk
-- promotion that applied to the sale
JOIN promotion p
    ON base.cs_promo_sk = p.p_promo_sk
-- demographic of the billing household
JOIN household_demographics hd_bill
    ON base.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
-- address of the billing customer
JOIN customer_address ca_bill
    ON base.cs_bill_addr_sk = ca_bill.ca_address_sk
-- possible catalog return linked by order number
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = base.cs_order_number
-- time of the catalog return
LEFT JOIN time_dim td_return
    ON cr.cr_returned_time_sk = td_return.t_time_sk
-- reason for the catalog return (first alias)
LEFT JOIN reason reason_cr
    ON cr.cr_reason_sk = reason_cr.r_reason_sk
-- demographic of the refunded household
LEFT JOIN household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
-- address of the refunded customer
LEFT JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
-- store return events (joined via the same time dimension used for sales)
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = td_sold.t_time_sk
-- demographic of the store‑return household
LEFT JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
-- address of the store‑return customer
LEFT JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
-- reason for the store return (second alias)
LEFT JOIN reason reason_sr
    ON sr.sr_reason_sk = reason_sr.r_reason_sk
GROUP BY
    cp.cp_department,
    p.p_channel_dmail,
    td_sold.t_shift
