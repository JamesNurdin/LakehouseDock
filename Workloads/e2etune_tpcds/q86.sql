WITH sales_enriched AS (
  SELECT
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    sd.d_year AS sold_year,
    sd.d_quarter_name AS sold_quarter,
    sh.d_year AS ship_year,
    sh.d_quarter_name AS ship_quarter,
    p.p_promo_name,
    p.p_channel_email,
    p.p_discount_active,
    p.p_cost,
    p.p_response_target,
    date_diff('day', sd.d_date, sh.d_date) AS shipping_days
  FROM web_sales ws
  JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
  JOIN date_dim sh ON ws.ws_ship_date_sk = sh.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE sd.d_current_year = 'Y'
    AND p.p_discount_active = 'Y'
)
SELECT
  sold_year,
  p_promo_name,
  COALESCE(p_channel_email, 'N/A') AS promo_channel_email,
  SUM(ws_net_profit) AS total_net_profit,
  SUM(ws_ext_discount_amt) AS total_discount,
  COUNT(DISTINCT ws_order_number) AS distinct_orders,
  AVG(ws_ext_discount_amt) AS avg_discount_per_order,
  AVG(shipping_days) AS avg_shipping_days,
  RANK() OVER (PARTITION BY sold_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_enriched
GROUP BY
  sold_year,
  p_promo_name,
  p_channel_email
HAVING SUM(ws_net_profit) > 0
ORDER BY sold_year, profit_rank
