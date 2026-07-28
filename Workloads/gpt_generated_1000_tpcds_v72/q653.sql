WITH base AS (
   SELECT
     ca.ca_address_sk,
     ca.ca_state,
     cr.cr_net_loss AS cr_net_loss,
     sr.sr_net_loss AS sr_net_loss,
     ss.ss_ext_list_price,
     ss.ss_coupon_amt,
     cr.cr_return_amount,
     sr.sr_store_credit,
     ss.ss_ext_wholesale_cost,
     ss.ss_net_profit
   FROM catalog_returns cr
   JOIN customer_address ca
     ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN store_returns sr
     ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN store_sales ss
     ON ss.ss_item_sk = sr.sr_item_sk
    AND ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_addr_sk = ca.ca_address_sk
   WHERE cr.cr_return_amount > 1000
     AND sr.sr_store_credit > 10
     AND ss.ss_ext_list_price BETWEEN 1000 AND 8000
     AND ca.ca_state = 'CA'
     AND ca.ca_gmt_offset > -5
),
filtered AS (
   SELECT *
   FROM base b
   WHERE NOT EXISTS (
       SELECT 1
       FROM catalog_returns cr2
       WHERE cr2.cr_refunded_addr_sk = b.ca_address_sk
         AND cr2.cr_store_credit > 500
   )
)
SELECT
   ca_state,
   SUM(cr_net_loss) AS total_catalog_net_loss,
   SUM(sr_net_loss) AS total_store_net_loss,
   AVG(ss_coupon_amt) AS avg_coupon_amount,
   SUM(ss_ext_list_price) AS total_sales_list_price,
   ROW_NUMBER() OVER (ORDER BY SUM(sr_net_loss) DESC) AS rn_overall
FROM filtered
GROUP BY ca_state
ORDER BY total_store_net_loss DESC
LIMIT 100
