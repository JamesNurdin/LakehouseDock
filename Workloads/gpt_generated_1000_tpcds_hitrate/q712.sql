WITH filtered_returns AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       sr.sr_item_sk,
       sr.sr_customer_sk,
       sr.sr_addr_sk,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_net_loss,
       sr.sr_refunded_cash,
       sr.sr_store_credit,
       t.t_time_sk,
       t.t_shift,
       t.t_minute,
       ca.ca_county,
       ca.ca_address_sk
   FROM store_returns sr
   JOIN time_dim t
     ON sr.sr_return_time_sk = t.t_time_sk
   JOIN customer_address ca
     ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE t.t_shift = 'first'
     AND t.t_minute = 10
     AND ca.ca_county = 'York County'
)

SELECT
   fr.t_shift,
   fr.ca_county,
   COUNT(*) AS total_returns,
   SUM(fr.sr_return_amt) AS total_return_amount,
   AVG(fr.sr_net_loss) AS avg_net_loss,
   SUM(CASE WHEN fr.sr_refunded_cash > 100 THEN fr.sr_refunded_cash ELSE 0 END) AS high_refunded_cash,
   cr_agg.total_catalog_return_amount,
   cr_agg.max_refund_cash_per_address
FROM filtered_returns fr
JOIN catalog_returns cr
   ON cr.cr_refunded_addr_sk = fr.ca_address_sk
   AND cr.cr_returned_time_sk = fr.t_time_sk
JOIN (
   SELECT
       cr2.cr_refunded_addr_sk,
       SUM(cr2.cr_refunded_cash) AS total_catalog_return_amount,
       MAX(cr2.cr_refunded_cash) AS max_refund_cash_per_address
   FROM catalog_returns cr2
   GROUP BY cr2.cr_refunded_addr_sk
) cr_agg
   ON cr_agg.cr_refunded_addr_sk = fr.ca_address_sk
WHERE EXISTS (
   SELECT 1
   FROM catalog_returns cr3
   WHERE cr3.cr_refunded_addr_sk = fr.ca_address_sk
     AND cr3.cr_return_amount > 500
)
GROUP BY
   fr.t_shift,
   fr.ca_county,
   cr_agg.total_catalog_return_amount,
   cr_agg.max_refund_cash_per_address
ORDER BY total_return_amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
