WITH base AS (
   SELECT
       d.d_date,
       d.d_year,
       c.cc_name,
       w.w_state,
       r.r_reason_desc,
       r.r_reason_id,
       ss.ss_item_sk,
       ss.ss_store_sk,
       ss.ss_customer_sk,
       ss.ss_net_paid,
       cr.cr_return_amount,
       cr.cr_refunded_customer_sk,
       inv.inv_quantity_on_hand,
       ws.web_city
   FROM date_dim d
   JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_reason_sk = r.r_reason_sk
   JOIN call_center c ON cr.cr_call_center_sk = c.cc_call_center_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_item_sk = ss.ss_item_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
     AND c.cc_name LIKE 'Call Center %'
     AND w.w_state = 'CA'
     AND r.r_reason_id IN ('AAAAAAAADAAAAAAA','AAAAAAAALAAAAAAA')
     AND inv.inv_quantity_on_hand > 0
     AND ws.web_city = 'San Francisco'
     AND ss.ss_store_sk NOT IN (
         SELECT sr2.sr_store_sk FROM store_returns sr2 WHERE sr2.sr_return_quantity > 0
     )
),
agg_daily AS (
   SELECT
       d_date,
       r_reason_desc,
       SUM(ss_net_paid) AS total_sales,
       SUM(cr_return_amount) AS total_returns,
       COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
       COUNT(DISTINCT cr_refunded_customer_sk) AS distinct_refunded_customers
   FROM base
   GROUP BY d_date, r_reason_desc
),
cross_joined AS (
   SELECT
       a.d_date,
       a.r_reason_desc,
       a.total_sales,
       a.total_returns,
       a.distinct_customers,
       a.distinct_refunded_customers,
       a.total_sales - a.total_returns AS net_amount,
       flag
   FROM agg_daily a
   CROSS JOIN (SELECT 1 AS flag) t
),
final AS (
   SELECT
       AVG(net_amount) AS avg_daily_net,
       SUM(distinct_customers) AS total_distinct_customers,
       SUM(distinct_refunded_customers) AS total_distinct_refunded_customers,
       COUNT(DISTINCT r_reason_desc) AS distinct_reasons
   FROM cross_joined
   WHERE net_amount > 0
)
SELECT *
FROM final
LIMIT 100
