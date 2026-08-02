WITH sales_agg AS (
   SELECT
       cs_item_sk,
       cs_order_number,
       SUM(cs_net_paid) AS total_net_paid,
       SUM(cs_ext_sales_price) AS total_ext_sales_price,
       COUNT(*) AS sales_cnt
   FROM catalog_sales
   WHERE cs_call_center_sk IN (10, 13)
     AND cs_catalog_page_sk IN (23, 197)
     AND cs_wholesale_cost > 30.00
   GROUP BY cs_item_sk, cs_order_number
)
SELECT
    s.s_store_name,
    ca.ca_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amount,
    SUM(sa.total_net_paid) AS total_sales_net_paid,
    SUM(sa.total_ext_sales_price) AS total_sales_ext_price,
    AVG(cr.cr_net_loss) AS avg_return_net_loss
FROM sales_agg sa
JOIN catalog_returns cr
   ON cr.cr_item_sk = sa.cs_item_sk
   AND cr.cr_order_number = sa.cs_order_number
JOIN customer_address ca
   ON ca.ca_address_sk = cr.cr_refunded_addr_sk
LEFT JOIN store_returns sr
   ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN store s
   ON s.s_store_sk = sr.sr_store_sk
WHERE ca.ca_state = 'CA'
  AND cr.cr_refunded_cdemo_sk = 1115105
  AND cr.cr_refunded_hdemo_sk = 5112
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_addr_sk = cr.cr_refunded_addr_sk
      )
GROUP BY s.s_store_name, ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
