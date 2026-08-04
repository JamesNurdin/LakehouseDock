WITH unified AS (
  -- Store side rows
  SELECT
    ca.ca_state,
    td.t_hour,
    p.p_promo_name,
    ss.ss_ticket_number AS ticket,
    ss.ss_net_profit AS profit,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS sales,
    -- Correlated sub‑query: total return amount from web_returns for the same hour
    (SELECT SUM(wr.wr_return_amt)
     FROM web_returns wr
     JOIN time_dim td_corr ON wr.wr_returned_time_sk = td_corr.t_time_sk
     WHERE td_corr.t_hour = td.t_hour) AS wr_hourly_return_total,
    CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_return_time_sk = td.t_time_sk
  WHERE ca.ca_country = 'United States'
    AND ca.ca_state = 'CA'
    AND p.p_channel_tv = 'N'
    AND td.t_hour BETWEEN 9 AND 17
    AND ib.ib_upper_bound > 50000

  UNION DISTINCT

  -- Web side rows
  SELECT
    ca2.ca_state,
    td2.t_hour,
    p2.p_promo_name,
    ws.ws_order_number AS ticket,
    ws.ws_net_profit AS profit,
    ws.ws_quantity AS quantity,
    ws.ws_ext_sales_price AS sales,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     JOIN time_dim td_corr2 ON wr2.wr_returned_time_sk = td_corr2.t_time_sk
     WHERE td_corr2.t_hour = td2.t_hour) AS wr_hourly_return_total,
    CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
  FROM web_sales ws
  JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
  JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
  JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
  JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
  JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE ca2.ca_country = 'United States'
    AND ca2.ca_state = 'TX'
    AND wsite.web_class = 'Unknown'
    AND td2.t_hour BETWEEN 9 AND 17
    AND ib2.ib_lower_bound <= 30000
)
SELECT
  ca_state,
  t_hour,
  p_promo_name,
  COUNT(DISTINCT ticket)               AS cnt_tickets,
  SUM(profit)                          AS total_profit,
  AVG(quantity)                        AS avg_quantity,
  SUM(sales)                           AS total_sales,
  SUM(wr_hourly_return_total)          AS total_wr_return,
  COUNT(CASE WHEN profit_flag = 'POS' THEN 1 END) AS pos_profit_cnt
FROM unified
GROUP BY CUBE (ca_state, t_hour, p_promo_name)
ORDER BY total_profit DESC
LIMIT 100
