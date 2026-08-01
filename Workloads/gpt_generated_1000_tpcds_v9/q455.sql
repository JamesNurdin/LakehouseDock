-- Goal: Summarize net sales and return amounts per item and promotion, with subtotals, filtered by recent call centers, moderate‑priced items, and TV‑inactive promotions. The result is further limited to items that appear both in sales and returns, and displayed per price‑range bucket.
WITH base AS (
   SELECT
       cc.cc_rec_start_date,
       cs.cs_net_paid,
       cr.cr_return_amount,
       i.i_item_id,
       i.i_current_price,
       p.p_promo_name,
       p.p_channel_tv,
       ss.ss_net_paid,
       sr.sr_return_amt,
       ws.ws_net_paid,
       wr.wr_return_amt
   FROM tpcds.call_center cc
   JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
   JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
   JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
   WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
     AND i.i_current_price > 20
     AND p.p_channel_tv = 'N'
),
agg_sales AS (
   SELECT
       i_item_id,
       p_promo_name,
       SUM(cs_net_paid) AS total_cs_net_paid,
       SUM(ss_net_paid) AS total_ss_net_paid,
       SUM(ws_net_paid) AS total_ws_net_paid,
       SUM(cr_return_amount) AS total_cr_return_amount,
       SUM(sr_return_amt) AS total_sr_return_amt,
       SUM(wr_return_amt) AS total_wr_return_amt
   FROM base
   GROUP BY GROUPING SETS (
       (i_item_id, p_promo_name),
       (i_item_id),
       (p_promo_name),
       ()
   )
),
price_brackets AS (
   SELECT 'Low'    AS price_range UNION ALL
   SELECT 'Medium'               UNION ALL
   SELECT 'High'
),
filtered_items AS (
   SELECT i_item_id
   FROM (SELECT DISTINCT i_item_id FROM base WHERE cs_net_paid > 0) AS a
   INTERSECT
   SELECT i_item_id FROM (SELECT DISTINCT i_item_id FROM base WHERE cr_return_amount > 0) AS b
)
SELECT
   pb.price_range,
   a.i_item_id,
   a.p_promo_name,
   a.total_cs_net_paid,
   a.total_ss_net_paid,
   a.total_ws_net_paid,
   a.total_cr_return_amount,
   a.total_sr_return_amt,
   a.total_wr_return_amt
FROM agg_sales a
JOIN filtered_items f ON a.i_item_id = f.i_item_id
CROSS JOIN price_brackets pb
WHERE CASE 
        WHEN a.total_cs_net_paid < 5000  THEN 'Low'
        WHEN a.total_cs_net_paid < 20000 THEN 'Medium'
        ELSE 'High'
      END = pb.price_range
ORDER BY a.i_item_id, a.p_promo_name
LIMIT 100
