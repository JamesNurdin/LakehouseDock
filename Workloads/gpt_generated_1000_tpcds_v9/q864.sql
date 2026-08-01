/*
  Query: Total net profit and return loss by store and year, segmenting customers by credit rating,
  counting damaged returns, and excluding any sales that have a matching store return.
*/
SELECT
    s.s_store_name AS store_name,
    d_sales.d_year AS sales_year,
    CASE WHEN cd_ss.cd_credit_rating = 'Good' THEN 'High Credit' ELSE 'Other Credit' END AS credit_category,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN 1 ELSE 0 END) AS damaged_return_count
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_demographics cd_ss
  ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN customer_address ca_ss
  ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_store_sk = s.s_store_sk
     AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sales.d_date_sk
     AND cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN inventory inv
  ON inv.inv_date_sk = d_sales.d_date_sk
LEFT JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_sales.d_date_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_returns sr_chk
    WHERE sr_chk.sr_ticket_number = ss.ss_ticket_number
)
GROUP BY
    s.s_store_name,
    d_sales.d_year,
    CASE WHEN cd_ss.cd_credit_rating = 'Good' THEN 'High Credit' ELSE 'Other Credit' END
ORDER BY total_store_net_profit DESC
LIMIT 100
