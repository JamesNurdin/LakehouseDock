WITH joined_data AS (
  SELECT
    d.d_year,
    d.d_date,
    cc.cc_name,
    cs.cs_net_profit,
    ss.ss_net_profit,
    sr.sr_net_loss,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    p.p_channel_catalog,
    w.w_city,
    wp.wp_type,
    ws.ws_net_profit,
    web_site.web_manager
  FROM tpcds.date_dim d
  JOIN tpcds.call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
   AND s.s_closed_date_sk = d.d_date_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
   AND p.p_start_date_sk = d.d_date_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_returned_date_sk = d.d_date_sk
  JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_bill_addr_sk = ca.ca_address_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
   AND wp.wp_creation_date_sk = d.d_date_sk
  JOIN tpcds.web_site web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
   AND web_site.web_open_date_sk = d.d_date_sk
)
SELECT
  d_year,
  s_store_id,
  s_store_name,
  SUM(ss_net_profit) AS store_sales_profit,
  SUM(cs_net_profit) AS catalog_sales_profit,
  SUM(ws_net_profit) AS web_sales_profit,
  SUM(sr_net_loss) AS returns_loss,
  (SUM(ss_net_profit) + SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(sr_net_loss)) AS total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (SUM(ss_net_profit) + SUM(cs_net_profit) + SUM(ws_net_profit) - SUM(sr_net_loss)) DESC) AS profit_rank
FROM joined_data
WHERE d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
  AND cc_name = 'Main'
  AND p_channel_catalog = 'Y'
  AND s_state = 'CA'
  AND w_city = 'Houston'
  AND wp_type = 'A'
  AND web_manager = 'John Doe'
GROUP BY d_year, s_store_id, s_store_name
ORDER BY d_year, profit_rank
