WITH joined_data AS (
  SELECT
    s.s_store_name,
    p.p_promo_name,
    d_sales.d_year,
    ss.ss_net_paid AS ss_net_paid,
    cs.cs_net_paid AS cs_net_paid,
    ws.ws_net_paid AS ws_net_paid,
    sr.sr_return_amt AS sr_return_amt,
    wr.wr_return_amt AS wr_return_amt,
    r_store.r_reason_desc AS store_return_reason,
    r_web.r_reason_desc AS web_return_reason,
    t.t_hour,
    wp.wp_url
  FROM store s
  JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
   AND cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_returned_date_sk = d_sales.d_date_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r_store
    ON r_store.r_reason_sk = sr.sr_reason_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
   AND wr.wr_order_number = ws.ws_order_number
   AND wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN reason r_web
    ON r_web.r_reason_sk = wr.wr_reason_sk
  LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
  LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
)
SELECT
  s_store_name,
  p_promo_name,
  d_year,
  SUM(ss_net_paid) AS total_store_sales,
  SUM(cs_net_paid) AS total_catalog_sales,
  SUM(ws_net_paid) AS total_web_sales,
  SUM(sr_return_amt) AS total_store_returns,
  SUM(wr_return_amt) AS total_web_returns,
  (SUM(ss_net_paid) + SUM(cs_net_paid) + SUM(ws_net_paid) - SUM(sr_return_amt) - SUM(wr_return_amt)) AS net_total,
  RANK() OVER (PARTITION BY d_year ORDER BY (SUM(ss_net_paid) + SUM(cs_net_paid) + SUM(ws_net_paid) - SUM(sr_return_amt) - SUM(wr_return_amt)) DESC) AS profit_rank,
  MAX(t_hour) AS peak_sale_hour,
  COUNT(DISTINCT wp_url) AS distinct_pages_visited
FROM joined_data
GROUP BY s_store_name, p_promo_name, d_year
ORDER BY d_year, profit_rank
LIMIT 100
