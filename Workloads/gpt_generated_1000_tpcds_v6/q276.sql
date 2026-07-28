WITH sales_promo AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ship_mode_sk,
    cs.cs_ship_hdemo_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_ext_list_price,
    cs.cs_net_paid_inc_tax,
    cs.cs_net_profit,
    p.p_promo_name,
    p.p_channel_tv,
    p.p_channel_event,
    p.p_discount_active
  FROM catalog_sales cs
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_ship_hdemo_sk IN (6547, 3839, 1703)
    AND cs.cs_ship_mode_sk = 3
    AND cs.cs_ext_list_price > 5000
    AND cs.cs_quantity BETWEEN 1 AND 5
    AND cs.cs_net_paid_inc_tax < 10000
    AND p.p_channel_event = 'N'
    AND p.p_discount_active = 'Y'
)
SELECT
  COALESCE(p_promo_name, 'All Promotions') AS promo_name,
  COALESCE(p_channel_tv, 'All TV Channels') AS channel_tv,
  COALESCE(cs_ship_mode_sk, -1) AS ship_mode,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cs_net_profit) AS total_profit,
  AVG(cs_quantity) AS avg_quantity,
  COUNT(*) AS sales_cnt
FROM sales_promo
GROUP BY GROUPING SETS (
  (p_promo_name, p_channel_tv, cs_ship_mode_sk),
  (p_promo_name, p_channel_tv),
  (p_promo_name),
  ()
)
ORDER BY
  CASE WHEN GROUPING(p_promo_name) = 0 THEN 1 ELSE 2 END,
  total_sales DESC
LIMIT 100
