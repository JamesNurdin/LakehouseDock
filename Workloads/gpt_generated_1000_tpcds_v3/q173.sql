WITH base AS (
  SELECT
    d_sales.d_year,
    i.i_category,
    i.i_item_id,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss,
    (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)) AS total_net_profit
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk AND cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d_cat ON cs.cs_sold_date_sk = d_cat.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk AND ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
  WHERE d_sales.d_year = 2001
    AND i.i_category = 'Sports'
    AND cs.cs_sales_price > 50
    AND ss.ss_quantity >= 5
    AND sm_cs.sm_type = 'AIR'
    AND cc.cc_state = 'CA'
    AND cp.cp_type = 'PROMO'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND EXISTS (
      SELECT 1
      FROM web_page wp
      WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
        AND wp.wp_url LIKE '%example.com%'
    )
  GROUP BY d_sales.d_year, i.i_category, i.i_item_id
)
SELECT
  d_year,
  i_category,
  i_item_id,
  store_net_profit,
  store_return_loss,
  catalog_net_profit,
  catalog_return_loss,
  web_net_profit,
  web_return_loss,
  total_net_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM base
ORDER BY total_net_profit DESC
LIMIT 10
