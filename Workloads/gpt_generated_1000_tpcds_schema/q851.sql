WITH base_returns AS (
   SELECT
      cr.cr_returned_date_sk,
      d.d_date,
      cr.cr_item_sk,
      i.i_item_id,
      i.i_product_name,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_return_amt_inc_tax,
      cr.cr_fee,
      cr.cr_reason_sk,
      r.r_reason_desc,
      cr.cr_ship_mode_sk,
      sm.sm_carrier,
      cr.cr_call_center_sk,
      cc.cc_name,
      cr.cr_catalog_page_sk,
      cp.cp_catalog_number,
      cr.cr_refunded_addr_sk,
      ca_refunded.ca_city AS refunded_city,
      cr.cr_returning_addr_sk,
      ca_returning.ca_state AS returning_state,
      cr.cr_order_number
   FROM catalog_returns cr
   JOIN date_dim d                ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i                    ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r                  ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN customer_address ca_refunded   ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
   JOIN customer_address ca_returning  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
),
sales_agg AS (
   SELECT
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      SUM(ss.ss_net_paid)      AS total_net_paid,
      SUM(ss.ss_quantity)      AS total_quantity
   FROM store_sales ss
   GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
),
web_agg AS (
   SELECT
      wr.wr_item_sk,
      wr.wr_returned_date_sk,
      SUM(wr.wr_return_amt)    AS total_wr_amt
   FROM web_returns wr
   GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
)
SELECT
   br.cr_returned_date_sk,
   br.d_date,
   br.i_item_id,
   br.i_product_name,
   CASE WHEN br.cr_return_amount > 500 THEN 'HIGH' ELSE 'LOW' END AS return_level,
   (br.cr_return_amount + br.cr_return_tax + br.cr_fee) AS total_return_amount,
   s.total_net_paid,
   w.total_wr_amt,
   ROW_NUMBER() OVER (PARTITION BY br.d_date ORDER BY (br.cr_return_amount + br.cr_return_tax + br.cr_fee) DESC) AS rn_day,
   (SELECT COUNT(*)
      FROM store_sales ss2
      WHERE ss2.ss_item_sk = br.cr_item_sk
        AND ss2.ss_sold_date_sk = br.cr_returned_date_sk) AS sales_txn_count,
   u.metric_value,
   CASE WHEN u.metric_idx = 1 THEN 'Quantity' ELSE 'Amount' END AS metric_type
FROM (
   SELECT *
   FROM base_returns
   WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
     AND sm_carrier = 'DIAMOND'
     AND cc_name LIKE 'West%'
) br
LEFT JOIN sales_agg s
   ON br.cr_item_sk = s.ss_item_sk
  AND br.cr_returned_date_sk = s.ss_sold_date_sk
LEFT JOIN web_agg w
   ON br.cr_item_sk = w.wr_item_sk
  AND br.cr_returned_date_sk = w.wr_returned_date_sk
CROSS JOIN UNNEST(ARRAY[br.cr_return_quantity, br.cr_return_amount]) WITH ORDINALITY AS u(metric_value, metric_idx)
WHERE NOT EXISTS (
   SELECT 1
   FROM web_returns wr2
   WHERE wr2.wr_order_number = br.cr_order_number
     AND wr2.wr_returned_date_sk = br.cr_returned_date_sk
)
ORDER BY br.d_date, rn_day
LIMIT 100
