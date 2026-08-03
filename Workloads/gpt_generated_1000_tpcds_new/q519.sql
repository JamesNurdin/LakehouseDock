WITH
  sales_data AS (
    SELECT
      i.i_brand,
      i.i_category,
      cs.cs_item_sk,
      SUM(cs.cs_ext_sales_price)       AS total_sales,
      SUM(cs.cs_net_profit)            AS total_profit
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_sales_price > 1000
    GROUP BY CUBE(i.i_brand, i.i_category, cs.cs_item_sk)
  ),
  promo_full AS (
    SELECT
      s.i_brand,
      s.i_category,
      s.total_sales,
      s.total_profit,
      p.p_promo_name,
      s.cs_item_sk
    FROM sales_data s
    FULL OUTER JOIN promotion p
      ON p.p_item_sk = s.cs_item_sk
    CROSS JOIN LATERAL (
      SELECT p2.p_promo_name
      FROM promotion p2
      WHERE p2.p_item_sk = s.cs_item_sk
      ORDER BY p2.p_response_target DESC
      LIMIT 1
    ) latest
  ),
  returns_data AS (
    SELECT
      i.i_brand,
      i.i_category,
      sr.sr_item_sk,
      SUM(sr.sr_return_amt_inc_tax) AS total_return,
      SUM(sr.sr_net_loss)          AS total_loss
    FROM store_returns sr
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_amt_inc_tax > 0
    GROUP BY CUBE(i.i_brand, i.i_category, sr.sr_item_sk)
  ),
  combined AS (
    SELECT
      pf.i_brand,
      pf.i_category,
      pf.total_sales,
      pf.total_profit,
      pf.p_promo_name,
      NULL AS total_return,
      NULL AS total_loss
    FROM promo_full pf
    UNION ALL
    SELECT
      rd.i_brand,
      rd.i_category,
      NULL AS total_sales,
      NULL AS total_profit,
      NULL AS p_promo_name,
      rd.total_return,
      rd.total_loss
    FROM returns_data rd
  )
SELECT
  c.i_brand,
  c.i_category,
  c.total_sales,
  c.total_profit,
  c.p_promo_name,
  c.total_return,
  c.total_loss,
  d.dim_brand
FROM combined c
CROSS JOIN (
  SELECT DISTINCT i_brand AS dim_brand
  FROM item
  LIMIT 10
) d
WHERE c.i_brand NOT IN (
  SELECT i_brand
  FROM returns_data
  WHERE total_loss > 5000
)
ORDER BY c.i_brand NULLS LAST,
         c.i_category NULLS LAST
LIMIT 100
