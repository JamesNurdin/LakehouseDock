WITH store AS (
  SELECT
    d_sale.d_month_seq AS month_seq,
    i.i_category AS category,
    ss.ss_net_profit AS net_profit,
    CASE
      WHEN d_sale.d_date >= d_start.d_date
           AND d_sale.d_date <= d_end.d_date THEN 1
      ELSE 0
    END AS promo_active_flag
  FROM store_sales ss
  JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
),
catalog AS (
  SELECT
    d_sale.d_month_seq AS month_seq,
    i.i_category AS category,
    cs.cs_net_profit AS net_profit,
    CASE
      WHEN d_sale.d_date >= d_start.d_date
           AND d_sale.d_date <= d_end.d_date THEN 1
      ELSE 0
    END AS promo_active_flag
  FROM catalog_sales cs
  JOIN date_dim d_sale ON cs.cs_sold_date_sk = d_sale.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
),
web AS (
  SELECT
    d_sale.d_month_seq AS month_seq,
    i.i_category AS category,
    ws.ws_net_profit AS net_profit,
    CASE
      WHEN d_sale.d_date >= d_start.d_date
           AND d_sale.d_date <= d_end.d_date THEN 1
      ELSE 0
    END AS promo_active_flag
  FROM web_sales ws
  JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
)
SELECT
  month_seq,
  category,
  SUM(net_profit) AS total_net_profit,
  SUM(CASE WHEN promo_active_flag = 1 THEN net_profit ELSE 0 END) AS promo_net_profit,
  CASE
    WHEN SUM(net_profit) = 0 THEN 0
    ELSE ROUND(100.0 * SUM(CASE WHEN promo_active_flag = 1 THEN net_profit ELSE 0 END) / SUM(net_profit), 2)
  END AS promo_profit_percentage
FROM (
  SELECT month_seq, category, net_profit, promo_active_flag FROM store
  UNION ALL
  SELECT month_seq, category, net_profit, promo_active_flag FROM catalog
  UNION ALL
  SELECT month_seq, category, net_profit, promo_active_flag FROM web
) all_sales
GROUP BY month_seq, category
ORDER BY month_seq, category
