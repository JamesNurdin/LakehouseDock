WITH sales AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    ss.ss_quantity,
    ss.ss_cdemo_sk,
    ss.ss_promo_sk,
    d.d_year,
    d.d_moy,
    p.p_channel_tv,
    p.p_channel_email,
    ws.web_gmt_offset,
    ws.web_country
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN web_site ws ON ws.web_open_date_sk = p.p_start_date_sk
  WHERE cd.cd_purchase_estimate >= 1500
    AND cd.cd_credit_rating = 'Good'
    AND d.d_year BETWEEN 2000 AND 2002
    AND (p.p_channel_tv = 'Y' OR p.p_channel_email = 'Y')
    AND ws.web_gmt_offset >= 0
    AND ws.web_country = 'United States'
),
returns AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month
  FROM store_returns sr
  JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  WHERE sr.sr_return_quantity > 0
),
aggregated AS (
  SELECT
    s.d_year,
    s.d_moy AS month,
    s.p_channel_tv,
    s.p_channel_email,
    s.web_gmt_offset,
    SUM(s.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(r.sr_return_amt, 0)) AS total_return_amount,
    SUM(s.ss_net_profit) - SUM(COALESCE(r.sr_return_amt, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT s.ss_ticket_number) AS num_sales
  FROM sales s
  LEFT JOIN returns r ON s.ss_ticket_number = r.sr_ticket_number
  GROUP BY s.d_year, s.d_moy, s.p_channel_tv, s.p_channel_email, s.web_gmt_offset
  HAVING SUM(s.ss_net_profit) > 0
)
SELECT
  a.d_year,
  a.month,
  a.p_channel_tv,
  a.p_channel_email,
  a.web_gmt_offset,
  a.total_net_profit,
  a.total_return_amount,
  a.net_profit_after_returns,
  a.num_sales,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.d_year, a.month, a.total_net_profit DESC
LIMIT 100
