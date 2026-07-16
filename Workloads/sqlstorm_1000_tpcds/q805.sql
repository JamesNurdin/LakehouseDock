WITH sales AS (
  SELECT
    ss.ss_ticket_number AS ticket_number,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_store_sk AS store_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_promo_sk AS promo_sk
  FROM store_sales ss
), returns_agg AS (
  SELECT
    sr.sr_ticket_number AS ticket_number,
    SUM(sr.sr_return_quantity) AS return_quantity,
    SUM(sr.sr_net_loss) AS net_loss
  FROM store_returns sr
  GROUP BY sr.sr_ticket_number
)
SELECT
  d.d_year,
  s.s_state,
  i.i_category,
  i.i_brand,
  p.p_promo_name,
  SUM(sales.quantity) AS total_quantity,
  SUM(sales.net_paid) AS total_sales,
  SUM(sales.net_profit) AS total_profit,
  SUM(COALESCE(returns_agg.return_quantity, 0)) AS total_return_quantity,
  SUM(COALESCE(returns_agg.net_loss, 0)) AS total_return_loss,
  SUM(sales.net_paid) - SUM(COALESCE(returns_agg.net_loss, 0)) AS net_revenue,
  COUNT(DISTINCT sales.ticket_number) AS distinct_orders
FROM sales
JOIN store s ON sales.store_sk = s.s_store_sk
JOIN date_dim d ON sales.date_sk = d.d_date_sk
JOIN item i ON sales.item_sk = i.i_item_sk
LEFT JOIN promotion p ON sales.promo_sk = p.p_promo_sk
LEFT JOIN returns_agg ON sales.ticket_number = returns_agg.ticket_number
WHERE d.d_year = 2001
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND (p.p_channel_email = 'Y' OR p.p_channel_email IS NULL)
GROUP BY d.d_year, s.s_state, i.i_category, i.i_brand, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
