WITH web_sales_agg AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
    SUM(ws.ws_ext_sales_price) AS amount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END
  HAVING SUM(ws.ws_ext_sales_price) > 10000
),
store_returns_agg AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 'HighPotential' ELSE 'Other' END AS promo_type,
    SUM(sr.sr_return_amt) AS amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category,
    CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 'HighPotential' ELSE 'Other' END
  HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT year, category, promo_type, amount
FROM web_sales_agg
UNION ALL
SELECT year, category, promo_type, amount
FROM store_returns_agg
ORDER BY year, amount DESC
LIMIT 100
