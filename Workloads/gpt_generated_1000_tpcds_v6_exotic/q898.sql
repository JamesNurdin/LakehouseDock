/* Goal: Summarize return activity by refunded customer and item brand, showing subtotals and overall totals, and keep only groups where the combined net loss exceeds 1,000. */
SELECT
    c_refund.c_customer_id AS refunded_customer_id,
    i.i_brand AS item_brand,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
JOIN web_returns wr
  ON i.i_item_sk = wr.wr_item_sk
JOIN customer c_refund
  ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer c_return
  ON cr.cr_returning_customer_sk = c_return.c_customer_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN customer_address ca_current
  ON c_refund.c_current_addr_sk = ca_current.ca_address_sk
JOIN customer_address ca_wr_refund
  ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_return
  ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
GROUP BY GROUPING SETS (
    (c_refund.c_customer_id, i.i_brand),
    (c_refund.c_customer_id),
    (i.i_brand),
    ()
)
HAVING SUM(cr.cr_net_loss + wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
