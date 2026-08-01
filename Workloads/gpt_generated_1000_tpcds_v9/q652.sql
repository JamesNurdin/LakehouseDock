SELECT
  i.i_brand AS brand,
  d_ss.d_date AS sale_date,
  SUM(ss.ss_net_profit) AS total_sales_profit,
  SUM(sr.sr_net_loss) AS total_return_loss,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales,
  COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
  AVG(i.i_current_price) AS avg_current_price,
  COUNT(u.word) AS total_description_word_count
FROM
  store_sales ss
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
  LEFT JOIN income_band ib_sales ON hd_sales.hd_income_band_sk = ib_sales.ib_income_band_sk
  LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_ss.d_date_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_ss.d_date_sk
  LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
  LEFT JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
  LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_ss.d_date_sk AND ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS u(word)
WHERE
  d_ss.d_year = 2001
  AND t_ss.t_hour BETWEEN 9 AND 17
  AND i.i_current_price > 10
  AND EXISTS (
    SELECT 1 FROM web_sales ws2
    WHERE ws2.ws_order_number = ws.ws_order_number
      AND ws2.ws_net_profit > ss.ss_net_profit
  )
GROUP BY
  i.i_brand,
  d_ss.d_date
HAVING
  SUM(ss.ss_net_profit) > 10000
ORDER BY
  total_sales_profit DESC,
  brand
LIMIT 100
