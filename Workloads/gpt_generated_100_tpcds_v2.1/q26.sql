SELECT
    w.w_warehouse_name,
    w.w_state AS warehouse_state,
    ca.ca_state AS address_state,
    CASE 
        WHEN cr.cr_return_quantity > 20 THEN 'LargeQty'
        WHEN cr.cr_return_quantity > 10 THEN 'MediumQty'
        ELSE 'SmallQty'
    END AS qty_category,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_combined_net_loss,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    MAX(sr.sr_return_amt) AS max_store_return_amt,
    MIN(wr.wr_return_amt) AS min_web_return_amt
FROM catalog_returns cr
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_returns wr ON wr.wr_returning_addr_sk = ca.ca_address_sk
WHERE cr.cr_item_sk = 210145
  AND sr.sr_reason_sk IN (14, 35)
  AND sr.sr_return_amt > 500.00
  AND wr.wr_web_page_sk = 188
GROUP BY
    w.w_warehouse_name,
    w.w_state,
    ca.ca_state,
    CASE 
        WHEN cr.cr_return_quantity > 20 THEN 'LargeQty'
        WHEN cr.cr_return_quantity > 10 THEN 'MediumQty'
        ELSE 'SmallQty'
    END
ORDER BY total_combined_net_loss DESC
LIMIT 100
