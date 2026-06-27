WITH sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    td.t_hour AS hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    COUNT(DISTINCT ss.ss_promo_sk) AS num_promos
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  GROUP BY ss.ss_store_sk, td.t_hour
),
returns_agg AS (
  SELECT
    sr.sr_store_sk AS store_sk,
    td.t_hour AS hour,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_return_tickets
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  GROUP BY sr.sr_store_sk, td.t_hour
)
SELECT
  s.s_store_name,
  sales.hour,
  sales.total_sales,
  sales.total_discount,
  sales.total_promo_cost,
  sales.total_net_profit,
  COALESCE(returns.total_net_loss, 0) AS total_net_loss,
  (sales.total_net_profit - COALESCE(returns.total_net_loss, 0)) AS net_profit_after_returns,
  sales.num_tickets,
  sales.num_promos,
  COALESCE(returns.num_return_tickets, 0) AS num_return_tickets
FROM sales_agg sales
LEFT JOIN returns_agg returns
  ON sales.store_sk = returns.store_sk
  AND sales.hour = returns.hour
JOIN store s ON sales.store_sk = s.s_store_sk
ORDER BY s.s_store_name, sales.hour
