WITH base AS (
  SELECT
    s.s_store_name,
    d.d_year,
    ss.ss_net_paid,
    ws.ws_net_paid,
    sr.sr_return_amt_inc_tax,
    wr.wr_return_amt_inc_tax
  FROM tpcds.date_dim d
  JOIN tpcds.call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN tpcds.item i
    ON i.i_item_sk = cs.cs_item_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.store s
    ON s.s_store_sk = ss.ss_store_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN tpcds.reason r
    ON r.r_reason_sk = sr.sr_reason_sk
  JOIN tpcds.customer_address ca
    ON ca.ca_address_sk = sr.sr_addr_sk
  JOIN tpcds.household_demographics hd
    ON hd.hd_demo_sk = sr.sr_hdemo_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  WHERE d.d_year = 2000
    AND cc.cc_state = 'TX'
    AND i.i_brand = 'Brand#45'
    AND s.s_state = 'CA'
    AND ws.ws_quantity > 5
    AND cr.cr_return_quantity > 0
)
SELECT
  s_store_name,
  SUM(ss_net_paid) AS total_store_sales,
  SUM(ws_net_paid) AS total_web_sales,
  SUM(sr_return_amt_inc_tax) AS total_store_returns,
  SUM(wr_return_amt_inc_tax) AS total_web_returns,
  (SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(sr_return_amt_inc_tax) - SUM(wr_return_amt_inc_tax)) AS net_total,
  RANK() OVER (ORDER BY (SUM(ss_net_paid) + SUM(ws_net_paid) - SUM(sr_return_amt_inc_tax) - SUM(wr_return_amt_inc_tax)) DESC) AS store_rank
FROM base
GROUP BY s_store_name
ORDER BY store_rank
LIMIT 10
