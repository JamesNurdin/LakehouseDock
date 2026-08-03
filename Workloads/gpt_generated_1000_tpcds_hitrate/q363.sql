WITH profit_by_quarter AS (
  SELECT
    dd.d_quarter_name,
    SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_channel_email = 'Y'
    AND dd.d_quarter_name = '1903Q3'
    AND ss.ss_item_sk IN (
      SELECT p2.p_item_sk
      FROM promotion p2
      WHERE p2.p_discount_active = 'Y'
    )
  GROUP BY dd.d_quarter_name
),
profit_by_quarter_2 AS (
  SELECT
    dd.d_quarter_name,
    SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE p.p_channel_catalog = 'N'
    AND dd.d_quarter_name = '1904Q4'
    AND EXISTS (
      SELECT 1
      FROM promotion p3
      WHERE p3.p_item_sk = ss.ss_item_sk
        AND p3.p_discount_active = 'Y'
    )
  GROUP BY dd.d_quarter_name
)
SELECT
  q.quarter,
  q.total_profit,
  RANK() OVER (ORDER BY q.total_profit DESC) AS profit_rank
FROM (
  SELECT d_quarter_name AS quarter, total_profit FROM profit_by_quarter
  UNION ALL
  SELECT d_quarter_name AS quarter, total_profit FROM profit_by_quarter_2
) q
ORDER BY q.total_profit DESC, q.quarter
