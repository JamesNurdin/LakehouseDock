/* goal: Identify the top seasonal promotions in 2022 that generated the highest net profit, using string pattern matching on promotion names, and compare each promotion's profit to the overall average net profit across all sales. */
WITH promo_sales AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    p.p_promo_id,
    p.p_cost,
    p.p_channel_event,
    d_sold.d_date AS sold_date,
    d_sold.d_holiday AS sold_holiday,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS total_sales,
    AVG(cs.cs_net_paid_inc_ship) AS avg_net_paid_inc_ship
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
  WHERE d_sold.d_holiday = 'Y'
    AND p.p_channel_event = 'Y'
    AND d_sold.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
  GROUP BY
    p.p_promo_sk,
    p.p_promo_name,
    p.p_promo_id,
    p.p_cost,
    p.p_channel_event,
    d_sold.d_date,
    d_sold.d_holiday,
    d_start.d_date,
    d_end.d_date
)
SELECT
  promo_sales.p_promo_sk,
  substring(promo_sales.p_promo_id, 1, 5) AS promo_prefix,
  concat(promo_sales.p_promo_name, ' (Cost ', CAST(promo_sales.p_cost AS varchar), ')') AS promo_full_desc,
  CASE
    WHEN regexp_like(promo_sales.p_promo_name, '(?i)black friday|holiday|christmas') THEN 'Seasonal'
    ELSE 'Regular'
  END AS promo_category,
  CASE
    WHEN promo_sales.p_channel_event = 'Y' THEN 'EventChannel'
    ELSE 'NoEventChannel'
  END AS channel_event_flag,
  CASE
    WHEN concat(promo_sales.p_promo_name, ' (Cost ', CAST(promo_sales.p_cost AS varchar), ')') LIKE '%Cost%' THEN 1
    ELSE 0
  END AS is_cost_mentioned,
  promo_sales.sold_date,
  promo_sales.promo_start_date,
  promo_sales.promo_end_date,
  promo_sales.total_net_profit,
  promo_sales.total_sales,
  promo_sales.avg_net_paid_inc_ship,
  CASE
    WHEN promo_sales.total_net_profit > (
      SELECT AVG(cs3.cs_net_profit)
      FROM catalog_sales cs3
      WHERE cs3.cs_quantity > 5
    ) THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS profit_vs_avg,
  RANK() OVER (ORDER BY promo_sales.total_net_profit DESC) AS net_profit_rank
FROM promo_sales
WHERE promo_sales.p_promo_name LIKE '%Discount%'
  AND regexp_like(promo_sales.p_promo_name, '(?i)black friday|holiday|christmas')
ORDER BY promo_sales.total_net_profit DESC
LIMIT 100
