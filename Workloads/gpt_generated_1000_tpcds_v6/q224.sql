WITH
  high_value_customers AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_ext_sales_price) > 10000
  ),
  returns_combined AS (
    SELECT cr.cr_item_sk AS item_sk,
           cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    WHERE EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = cr.cr_item_sk
              AND inv.inv_quantity_on_hand > 0
          )
    UNION ALL
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_customer_sk AS customer_sk,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    WHERE EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = sr.sr_item_sk
              AND inv.inv_quantity_on_hand > 0
          )
  )
SELECT
  i.i_category,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customer_cnt,
  SUM(rc.net_loss) AS total_net_loss,
  AVG(rc.net_loss) AS avg_net_loss,
  (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2) AS overall_avg_store_net_loss
FROM returns_combined rc
JOIN item i ON rc.item_sk = i.i_item_sk
JOIN customer c ON rc.customer_sk = c.c_customer_sk
JOIN high_value_customers hv ON rc.customer_sk = hv.customer_sk
WHERE regexp_like(i.i_item_desc, '(?i)bike')
  AND c.c_email_address LIKE '%@example.com'
GROUP BY i.i_category
ORDER BY total_net_loss DESC
LIMIT 100
