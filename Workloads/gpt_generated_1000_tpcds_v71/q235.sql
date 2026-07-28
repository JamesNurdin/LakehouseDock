WITH cs AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_net_profit,
        cs_quantity,
        cs_ext_sales_price,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_promo_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451362 AND 2451462
)
SELECT
    cp.cp_department,
    i.i_brand,
    sm.sm_type,
    p.p_promo_name,
    SUM(cs.cs_net_profit)                     AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number)       AS orders,
    COALESCE(SUM(cr.cr_return_amount), 0)    AS total_return_amount,
    COALESCE(COUNT(DISTINCT cr.cr_return_quantity), 0) AS return_transactions,
    COALESCE(SUM(ss.ss_ext_discount_amt), 0) AS total_store_discount,
    COALESCE(SUM(wr.wr_return_amt), 0)       AS total_web_return_amount
FROM cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
LEFT JOIN catalog_page cp_cr
    ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
LEFT JOIN time_dim t_cr_return
    ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
LEFT JOIN customer_address ca_cr_refund
    ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
LEFT JOIN customer_address ca_cr_return
    ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
JOIN store_sales ss
    ON ss.ss_item_sk = cs.cs_item_sk
JOIN time_dim t_store
    ON ss.ss_sold_time_sk = t_store.t_time_sk
JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN promotion p_store
    ON ss.ss_promo_sk = p_store.p_promo_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = cs.cs_item_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
LEFT JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
LEFT JOIN customer_address ca_wr_return
    ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = cs.cs_item_sk
      AND wr2.wr_returned_date_sk = cs.cs_sold_date_sk
)
  AND p.p_discount_active = 'Y'
GROUP BY
    cp.cp_department,
    i.i_brand,
    sm.sm_type,
    p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
