WITH sales_summary AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        SUM(cs_net_paid) AS order_net_paid,
        SUM(cs_net_profit) AS order_net_profit
    FROM catalog_sales
    GROUP BY cs_order_number, cs_item_sk
)
SELECT
    cr.cr_order_number,
    i1.i_category,
    t_cr.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    SUM(ss.order_net_paid) AS total_sales_summary_amount,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS overall_indicator
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN sales_summary ss
    ON cr.cr_order_number = ss.cs_order_number
   AND cr.cr_item_sk = ss.cs_item_sk
JOIN item i1
    ON cr.cr_item_sk = i1.i_item_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i1.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = cr.cr_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN item i2
    ON sr.sr_item_sk = i2.i_item_sk
JOIN customer_address ca_sr_addr
    ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_item_sk = cr.cr_item_sk
      AND sr2.sr_return_quantity > 0
)
GROUP BY GROUPING SETS (
    (cr.cr_order_number, i1.i_category, t_cr.t_hour),
    (cr.cr_order_number, i1.i_category),
    (cr.cr_order_number),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
