WITH recent_dates AS (
   SELECT d_date_sk
   FROM tpcds.date_dim
   WHERE d_year = 2001
),
agg AS (
   SELECT
       d_base.d_year AS d_year,
       i.i_category AS i_category,
       ca.ca_state AS ca_state,
       cc.cc_name AS cc_name,
       wp.wp_type AS wp_type,
       ws.web_name AS web_name,
       SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
       SUM(COALESCE(cs.cs_net_paid, 0)) AS total_sales_amount,
       SUM(COALESCE(cs.cs_net_profit, 0)) AS total_net_profit
   FROM tpcds.date_dim d_base
   LEFT JOIN tpcds.store_returns sr
       ON sr.sr_returned_date_sk = d_base.d_date_sk
   LEFT JOIN tpcds.item i
       ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN tpcds.customer_address ca
       ON sr.sr_addr_sk = ca.ca_address_sk
   LEFT JOIN tpcds.catalog_returns cr
       ON i.i_item_sk = cr.cr_item_sk
   LEFT JOIN tpcds.date_dim d_cr
       ON cr.cr_returned_date_sk = d_cr.d_date_sk
   LEFT JOIN tpcds.call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
   FULL OUTER JOIN tpcds.catalog_sales cs
       ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN tpcds.date_dim d_cs
       ON cs.cs_sold_date_sk = d_cs.d_date_sk
   LEFT JOIN tpcds.inventory inv
       ON i.i_item_sk = inv.inv_item_sk
   LEFT JOIN tpcds.date_dim d_inv
       ON inv.inv_date_sk = d_inv.d_date_sk
   LEFT JOIN tpcds.web_page wp
       ON wp.wp_creation_date_sk = d_base.d_date_sk
   LEFT JOIN tpcds.web_site ws
       ON ws.web_open_date_sk = d_base.d_date_sk
   WHERE EXISTS (
       SELECT 1 FROM recent_dates rd WHERE rd.d_date_sk = d_base.d_date_sk
   )
   GROUP BY
       d_base.d_year,
       i.i_category,
       ca.ca_state,
       cc.cc_name,
       wp.wp_type,
       ws.web_name
)
SELECT
   d_year,
   i_category,
   ca_state,
   cc_name,
   wp_type,
   web_name,
   total_store_return_amount,
   total_sales_amount,
   CASE WHEN total_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
   ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_store_return_amount DESC) AS yearly_return_rank
FROM agg
ORDER BY d_year, yearly_return_rank
OFFSET 0
LIMIT 100
