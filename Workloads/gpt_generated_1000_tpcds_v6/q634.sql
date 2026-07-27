WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_list_price,
    ws.ws_net_profit,
    wr.wr_net_loss,
    p.p_promo_name,
    p.p_channel_demo,
    wp.wp_type,
    wp.wp_rec_start_date,
    s.web_name,
    s.web_state,
    r.r_reason_desc
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
                       AND ws.ws_order_number = wr.wr_order_number
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE p.p_channel_demo = 'N'
    AND r.r_reason_desc LIKE '%price%'
    AND ws.ws_ext_list_price > 3000
    AND wp.wp_rec_start_date >= DATE '2022-01-01'
)
SELECT
  web_name,
  web_state,
  p_promo_name,
  r_reason_desc,
  COUNT(DISTINCT ws_order_number) AS order_cnt,
  SUM(ws_net_profit) AS total_profit,
  SUM(wr_net_loss) AS total_loss,
  AVG(ws_ext_list_price) AS avg_list_price,
  MAX(ws_ext_list_price) AS max_list_price,
  MIN(ws_ext_list_price) AS min_list_price,
  RANK() OVER (PARTITION BY web_name ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_returns
GROUP BY
  web_name,
  web_state,
  p_promo_name,
  r_reason_desc
ORDER BY total_profit DESC, profit_rank
LIMIT 100
