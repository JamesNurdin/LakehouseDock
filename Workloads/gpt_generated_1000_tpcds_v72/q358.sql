WITH sales_agg AS (
  SELECT
    ss.ss_sold_date_sk AS event_date_sk,
    i.i_category AS category,
    'store' AS source_type,
    SUM(ss.ss_ext_sales_price) AS amount,
    SUM(ss.ss_net_profit) AS profit,
    p.p_promo_name AS detail
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE i.i_current_price > 100
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY ss.ss_sold_date_sk, i.i_category, p.p_promo_name
),
returns_agg AS (
  SELECT
    cr.cr_returned_date_sk AS event_date_sk,
    i.i_category AS category,
    'catalog' AS source_type,
    SUM(cr.cr_return_amount) AS amount,
    -SUM(cr.cr_net_loss) AS profit,
    r.r_reason_desc AS detail
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE i.i_current_price > 100
    AND r.r_reason_desc LIKE '%damage%'
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY cr.cr_returned_date_sk, i.i_category, r.r_reason_desc
),
combined AS (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
)
SELECT
  c.event_date_sk,
  c.category,
  c.source_type,
  c.amount,
  c.profit,
  c.detail,
  CASE WHEN c.profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_indicator,
  (SELECT AVG(i2.i_current_price)
   FROM item i2
   WHERE i2.i_category = c.category) AS avg_category_price,
  ROW_NUMBER() OVER (PARTITION BY c.category ORDER BY c.amount DESC) AS rank_in_category
FROM combined c
ORDER BY c.amount DESC
LIMIT 100
