WITH agg AS (
  SELECT
    cc.cc_mkt_class AS market_class,
    i.i_category AS item_category,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(i.i_current_price) AS avg_item_price
  FROM call_center cc
  JOIN date_dim d_date ON cc.cc_open_date_sk = d_date.d_date_sk
  JOIN promotion p ON p.p_start_date_sk = d_date.d_date_sk
  JOIN item i ON p.p_item_sk = i.i_item_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d_date.d_date_sk
  WHERE d_date.d_year = 2000
    AND cc.cc_mkt_id IN (2, 3, 4)
    AND i.i_current_price > 100
    AND wp.wp_type IS NOT NULL
  GROUP BY cc.cc_mkt_class, i.i_category
)
SELECT
  market_class,
  item_category,
  promo_count,
  total_promo_cost,
  avg_item_price,
  RANK() OVER (PARTITION BY market_class ORDER BY total_promo_cost DESC) AS rank_in_market
FROM agg
ORDER BY market_class, rank_in_market
LIMIT 100
