WITH profit_events AS (
  -- Store sales (positive profit)
  SELECT date_trunc('month', d.d_date) AS month_start,
         p.p_promo_id,
         p.p_promo_name,
         ss.ss_net_profit AS profit_amount
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000

  UNION ALL

  -- Store returns (negative profit)
  SELECT date_trunc('month', d.d_date) AS month_start,
         p.p_promo_id,
         p.p_promo_name,
         -sr.sr_net_loss AS profit_amount
  FROM store_returns sr
  JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000

  UNION ALL

  -- Catalog sales (positive profit)
  SELECT date_trunc('month', d.d_date) AS month_start,
         p.p_promo_id,
         p.p_promo_name,
         cs.cs_net_profit AS profit_amount
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000

  UNION ALL

  -- Catalog returns (negative profit)
  SELECT date_trunc('month', d.d_date) AS month_start,
         p.p_promo_id,
         p.p_promo_name,
         -cr.cr_net_loss AS profit_amount
  FROM catalog_returns cr
  JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000

  UNION ALL

  -- Web sales (positive profit)
  SELECT date_trunc('month', d.d_date) AS month_start,
         p.p_promo_id,
         p.p_promo_name,
         ws.ws_net_profit AS profit_amount
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000

  UNION ALL

  -- Web returns (negative profit)
  SELECT date_trunc('month', d.d_date) AS month_start,
         p.p_promo_id,
         p.p_promo_name,
         -wr.wr_net_loss AS profit_amount
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
)
SELECT month_start,
       p_promo_id,
       p_promo_name,
       sum(profit_amount) AS total_profit
FROM profit_events
GROUP BY month_start, p_promo_id, p_promo_name
ORDER BY month_start, total_profit DESC
