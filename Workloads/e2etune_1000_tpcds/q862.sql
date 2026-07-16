WITH returns AS (
  SELECT
    d_ret.d_fy_quarter_seq AS quarter_seq,
    d_ret.d_year AS year,
    r.r_reason_desc AS reason,
    hd.hd_buy_potential AS buy_potential,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_fee > 50.0
    AND d_ret.d_year = 2002
  GROUP BY d_ret.d_fy_quarter_seq, d_ret.d_year, r.r_reason_desc, hd.hd_buy_potential
),
sales AS (
  SELECT
    d_sold.d_fy_quarter_seq AS quarter_seq,
    d_sold.d_year AS year,
    p.p_channel_email AS promo_channel,
    hd2.hd_buy_potential AS buy_potential,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
  WHERE p.p_discount_active = 'Y'
    AND d_sold.d_year = 2002
    AND ws.ws_net_profit > 0
  GROUP BY d_sold.d_fy_quarter_seq, d_sold.d_year, p.p_channel_email, hd2.hd_buy_potential
)
SELECT
  r.quarter_seq,
  r.year,
  r.reason,
  r.buy_potential,
  r.total_return_amount,
  r.total_net_loss,
  s.promo_channel,
  s.total_net_profit,
  r.total_net_loss / NULLIF(s.total_net_profit, 0) AS loss_to_profit_ratio,
  RANK() OVER (PARTITION BY r.quarter_seq ORDER BY r.total_net_loss DESC) AS loss_rank,
  ROW_NUMBER() OVER (PARTITION BY r.quarter_seq ORDER BY s.total_net_profit DESC) AS profit_rank
FROM returns r
JOIN sales s
  ON r.quarter_seq = s.quarter_seq
 AND r.year = s.year
 AND r.buy_potential = s.buy_potential
ORDER BY r.quarter_seq, loss_rank
LIMIT 50
