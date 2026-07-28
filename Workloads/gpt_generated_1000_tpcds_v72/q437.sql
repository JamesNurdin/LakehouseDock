WITH filtered_returns AS (
   SELECT *
   FROM catalog_returns
   WHERE cr_returned_date_sk BETWEEN 2450910 AND 2451065
     AND cr_fee > 20
     AND cr_fee < 90
     AND cr_return_ship_cost BETWEEN 50 AND 1200
     AND cr_return_quantity >= 1
     AND cr_return_amount > 0
)
SELECT
   cr.cr_returned_date_sk,
   ca_refunded.ca_state               AS refunded_state,
   ca_refunded.ca_street_type         AS refunded_street_type,
   ca_returning.ca_state              AS returning_state,
   ca_returning.ca_street_type        AS returning_street_type,
   SUM(cr.cr_return_quantity)         AS total_quantity,
   SUM(cr.cr_return_amount)           AS total_amount,
   AVG(cr.cr_fee)                     AS avg_fee,
   COUNT(*)                           AS return_count,
   CASE
       WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH_LOSS'
       WHEN SUM(cr.cr_net_loss) BETWEEN 0 AND 1000 THEN 'MEDIUM_LOSS'
       ELSE 'LOW_LOSS'
   END                                 AS loss_category,
   MIN(cr.cr_return_ship_cost)        AS min_ship_cost,
   MAX(cr.cr_return_ship_cost)        AS max_ship_cost
FROM filtered_returns cr
JOIN customer_address ca_refunded
  ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
WHERE ca_refunded.ca_street_type IN ('Boulevard', 'Road', 'Ct.')
  AND ca_returning.ca_street_type IN ('Circle', 'Cir.')
  AND ca_refunded.ca_gmt_offset = -5.00
  AND ca_returning.ca_gmt_offset = -7.00
  AND ca_refunded.ca_state = 'CA'
  AND ca_returning.ca_state = 'NY'
GROUP BY ROLLUP (
   cr.cr_returned_date_sk,
   ca_refunded.ca_state,
   ca_refunded.ca_street_type,
   ca_returning.ca_state,
   ca_returning.ca_street_type
)
ORDER BY cr.cr_returned_date_sk DESC,
         total_amount DESC
LIMIT 100
