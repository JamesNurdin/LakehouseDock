WITH base AS (
  SELECT
    w.web_name,
    p.p_promo_name,
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_quantity AS quantity,
    ws.ws_net_profit AS net_profit,
    COALESCE(wr.wr_return_amt_inc_tax, 0) AS return_amount,
    ws.ws_ext_discount_amt AS ext_discount_amt
  FROM web_sales ws
  JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
    AND p.p_discount_active = 'Y'
),
agg AS (
  SELECT
    web_name,
    p_promo_name,
    ws_sold_date_sk,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(quantity) AS total_quantity,
    SUM(net_profit) AS total_net_profit,
    SUM(return_amount) AS total_return_amount,
    SUM(net_profit) - SUM(return_amount) AS net_profit_after_returns,
    AVG(ext_discount_amt) AS avg_discount_amount
  FROM base
  GROUP BY web_name, p_promo_name, ws_sold_date_sk
  HAVING SUM(quantity) > 10
)
SELECT
  web_name,
  p_promo_name,
  ws_sold_date_sk,
  orders,
  total_quantity,
  total_net_profit,
  total_return_amount,
  net_profit_after_returns,
  avg_discount_amount,
  RANK() OVER (PARTITION BY web_name ORDER BY net_profit_after_returns DESC) AS site_daily_rank
FROM agg
ORDER BY net_profit_after_returns DESC
LIMIT 100
