WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    ws.ws_quantity,
    ws.ws_net_paid,
    sr.sr_net_loss,
    cr.cr_net_loss,
    i.i_category,
    i.i_brand,
    ws_site.web_state,
    td.t_hour,
    cc.cc_gmt_offset,
    cp.cp_department,
    r.r_reason_desc,
    wp.wp_image_count,
    inv.inv_quantity_on_hand
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  WHERE
    i.i_category = 'Sports'
    AND td.t_hour = 12
    AND ws_site.web_state = 'CA'
    AND cc.cc_gmt_offset = -5.00
)
SELECT
  i_category,
  i_brand,
  web_state,
  SUM(cs_net_paid) AS total_cs_net_paid,
  SUM(ws_net_paid) AS total_ws_net_paid,
  SUM(sr_net_loss) AS total_sr_net_loss,
  SUM(cr_net_loss) AS total_cr_net_loss,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  SUM(SUM(cs_net_paid)) OVER (PARTITION BY web_state) AS cs_net_paid_by_state
FROM base
GROUP BY i_category, i_brand, web_state
ORDER BY total_cs_net_paid DESC
LIMIT 10
