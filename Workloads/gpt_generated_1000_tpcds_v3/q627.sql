WITH base AS (
   SELECT
       cr.cr_order_number,
       cr.cr_returned_date_sk,
       d.d_date,
       d.d_year,
       d.d_month_seq,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_net_loss,
       r.r_reason_desc,
       sm.sm_type,
       sm.sm_code,
       p.p_promo_name,
       p.p_discount_active,
       inv.inv_quantity_on_hand,
       inv.inv_warehouse_sk,
       ws.ws_quantity AS ws_quantity,
       ws.ws_net_paid,
       ws.ws_net_profit,
       ca_refunded.ca_state AS refunded_state,
       ca_returning.ca_state AS returning_state,
       ca_bill.ca_state AS bill_state,
       ca_ship.ca_state AS ship_state,
       CASE 
           WHEN cr.cr_net_loss > 0 THEN 'Loss'
           WHEN cr.cr_return_amount > 0 THEN 'Refund'
           ELSE 'Other'
       END AS return_category
   FROM catalog_returns cr
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_address ca_refunded
     ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
   JOIN customer_address ca_returning
     ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN web_sales ws
     ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   LEFT JOIN inventory inv
     ON inv.inv_date_sk = d.d_date_sk
   LEFT JOIN customer_address ca_bill
     ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN customer_address ca_ship
     ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   WHERE d.d_year = 2001
     AND d.d_month_seq BETWEEN 1200 AND 1220
     AND ca_refunded.ca_state = 'CA'
     AND ca_returning.ca_state = 'CA'
     AND sm.sm_type = 'AIR'
     AND r.r_reason_desc LIKE '%Lost%'
     AND p.p_discount_active = 'Y'
     AND inv.inv_quantity_on_hand > 0
),
agg AS (
   SELECT
       d_year,
       r_reason_desc,
       SUM(cr_return_amount) AS total_return_amount,
       RANK() OVER (PARTITION BY d_year ORDER BY SUM(cr_return_amount) DESC) AS reason_rank_in_year
   FROM base
   GROUP BY d_year, r_reason_desc
)
SELECT
   b.cr_order_number,
   b.d_date,
   b.r_reason_desc,
   b.sm_type,
   b.p_promo_name,
   b.inv_quantity_on_hand,
   b.ws_net_paid,
   b.ws_net_profit,
   b.return_category,
   a.total_return_amount,
   a.reason_rank_in_year,
   ROW_NUMBER() OVER (PARTITION BY b.r_reason_desc ORDER BY b.cr_returned_date_sk DESC) AS recent_return_rownum,
   SUM(b.cr_return_amount) OVER (PARTITION BY b.r_reason_desc ORDER BY b.cr_returned_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_sum_last_3_returns
FROM base b
JOIN agg a
  ON b.d_year = a.d_year AND b.r_reason_desc = a.r_reason_desc
ORDER BY b.d_date DESC, b.cr_return_amount DESC
LIMIT 100
