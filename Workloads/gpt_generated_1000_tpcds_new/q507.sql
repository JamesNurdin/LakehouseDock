WITH
  -- Aggregate sales with string filters
  sales_agg AS (
    SELECT
      ws_item_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE regexp_like(CAST(ws_sales_price AS VARCHAR), '^1[0-9]')
      AND ws_ext_sales_price > 1000
    GROUP BY ws_item_sk
  ),
  -- Filter items with string processing
  item_filtered AS (
    SELECT
      i_item_sk,
      i_brand,
      i_category,
      i_manufact,
      substring(i_manufact FROM 1 FOR 5) AS manufact_prefix
    FROM item
    WHERE i_brand LIKE '%able%'
      AND regexp_like(i_manufact, '^.*able$')
  ),
  -- Intersection of the two key sets
  intersect_keys AS (
    SELECT ws_item_sk AS item_sk FROM sales_agg
    INTERSECT
    SELECT i_item_sk AS item_sk FROM item_filtered
  ),
  -- Keys present in item but never sold
  except_keys AS (
    SELECT i_item_sk AS item_sk FROM item
    EXCEPT
    SELECT ws_item_sk AS item_sk FROM web_sales
  ),
  -- Right outer join to keep all items that have no sales record in the aggregated set
  right_joined AS (
    SELECT
      i.i_item_sk AS item_sk,
      i.i_brand,
      COALESCE(s.total_sales, 0) AS total_sales
    FROM item i
    RIGHT OUTER JOIN sales_agg s
      ON i.i_item_sk = s.ws_item_sk
  ),
  -- Full outer join to keep unmatched rows from both sides
  full_joined AS (
    SELECT
      COALESCE(i.i_item_sk, s.ws_item_sk) AS item_sk,
      i.i_brand,
      i.i_category,
      s.total_sales
    FROM item i
    FULL OUTER JOIN sales_agg s
      ON i.i_item_sk = s.ws_item_sk
  ),
  -- Anti‑join: items that never appear in a high‑quantity order
  anti_joined AS (
    SELECT i.i_item_sk AS item_sk, i.i_brand
    FROM item i
    WHERE NOT EXISTS (
      SELECT 1 FROM web_sales ws
      WHERE ws.ws_item_sk = i.i_item_sk
        AND ws.ws_quantity > 10
    )
  )
SELECT
  fj.item_sk,
  fj.i_brand,
  fj.i_category,
  fj.total_sales,
  rj.total_sales AS right_total_sales,
  (fj.i_brand || '_' || fj.i_category) AS brand_category,
  CASE WHEN ik.item_sk IS NOT NULL THEN 1 ELSE 0 END AS in_intersect,
  CASE WHEN ek.item_sk IS NOT NULL THEN 1 ELSE 0 END AS in_except,
  CASE WHEN aj.item_sk IS NOT NULL THEN 1 ELSE 0 END AS in_anti
FROM full_joined fj
LEFT JOIN intersect_keys ik ON fj.item_sk = ik.item_sk
LEFT JOIN except_keys ek   ON fj.item_sk = ek.item_sk
LEFT JOIN right_joined rj   ON fj.item_sk = rj.item_sk
LEFT JOIN anti_joined aj    ON fj.item_sk = aj.item_sk
ORDER BY fj.total_sales DESC NULLS LAST
LIMIT 100
