WITH sales_agg AS (
  SELECT
    s.s_store_name,
    we.web_name,
    d.d_year,
    d.d_month_seq,
    i.i_product_name,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS store_sales_total,
    SUM(ws.ws_net_paid) AS web_sales_total,
    SUM(cs.cs_net_paid) AS catalog_sales_total,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_returns_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_returns_loss,
    SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) + SUM(cs.cs_net_paid)
        - SUM(COALESCE(sr.sr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0)) AS total_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
  JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND i.i_color = 'Red'
    AND p.p_discount_active = 'Y'
    AND we.web_company_id IN (1, 2)
  GROUP BY
    s.s_store_name,
    we.web_name,
    d.d_year,
    d.d_month_seq,
    i.i_product_name,
    p.p_promo_name
)
SELECT
  s_store_name,
  web_name,
  d_year,
  d_month_seq,
  i_product_name,
  p_promo_name,
  store_sales_total,
  web_sales_total,
  catalog_sales_total,
  store_returns_loss,
  web_returns_loss,
  total_profit,
  CASE WHEN total_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign,
  RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, profit_rank, s_store_name
LIMIT 100
