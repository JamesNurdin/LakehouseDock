WITH aggregated AS (
  SELECT
    w.web_country,
    w.web_state,
    p.p_promo_name,
    DATE_TRUNC('month', date_add('day', ws.ws_sold_date_sk, DATE '1970-01-01')) AS sales_month,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
    AND p.p_channel_tv = 'Y'
    AND w.web_country = 'United States'
    AND w.web_gmt_offset BETWEEN -6 AND -4
  GROUP BY w.web_country, w.web_state, p.p_promo_name, DATE_TRUNC('month', date_add('day', ws.ws_sold_date_sk, DATE '1970-01-01'))
)
SELECT
  a.web_country,
  a.web_state,
  a.p_promo_name,
  a.sales_month,
  a.total_quantity,
  a.total_net_paid,
  a.total_net_profit,
  a.avg_discount,
  RANK() OVER (PARTITION BY a.web_country ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.web_country, a.sales_month DESC, profit_rank
