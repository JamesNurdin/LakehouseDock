WITH
  -- Join sales to call_center with string processing and a lateral subquery
  joined AS (
    SELECT
      cs.cs_call_center_sk,
      cc.cc_name,
      cc.cc_manager,
      cc.cc_hours,
      cs.cs_ext_sales_price,
      cs.cs_ext_tax,
      cs.cs_quantity,
      CASE
        WHEN regexp_like(cc.cc_manager, '^Bob') THEN 'BobFamily'
        WHEN cc.cc_hours LIKE '%8AM-12AM%' THEN 'NightShift'
        ELSE 'Other'
      END AS manager_category,
      fn.first_name
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    CROSS JOIN LATERAL (
      SELECT regexp_extract(cc.cc_manager, '^([^ ]+)') AS first_name
    ) fn
    WHERE cs.cs_ext_tax > 50
  ),

  -- Small dimension used for a cross‑join
  rating_levels AS (
    SELECT CAST(v AS integer) AS rating
    FROM (VALUES (1), (2), (3), (4), (5)) t(v)
  ),

  -- Aggregate sales per call_center and derived rating, include a correlated subquery
  agg_sales AS (
    SELECT
      j.cs_call_center_sk,
      rl.rating,
      SUM(j.cs_ext_sales_price) AS total_sales,
      SUM(j.cs_quantity) AS total_qty,
      COUNT(*) AS txn_count,
      AVG(j.cs_ext_tax) AS avg_tax,
      (
        SELECT SUM(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = j.cs_call_center_sk
          AND cs2.cs_ext_tax > 200
      ) AS high_tax_sales
    FROM joined j
    CROSS JOIN rating_levels rl
    WHERE ((j.cs_quantity % 5) + 1) = rl.rating
    GROUP BY j.cs_call_center_sk, rl.rating
  ),

  -- Anti‑join: call_centers with no sales where quantity > 100
  no_big_sales AS (
    SELECT cc.cc_call_center_sk
    FROM call_center cc
    WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_sales cs
      WHERE cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cs.cs_quantity > 100
    )
  ),

  -- Key sets for EXCEPT operation
  key_set_a AS (
    SELECT cs.cs_call_center_sk AS cs_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 5000
  ),
  key_set_b AS (
    SELECT cs.cs_call_center_sk AS cs_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price < 1000
  ),
  key_diff AS (
    SELECT cs_sk FROM key_set_a
    EXCEPT
    SELECT cs_sk FROM key_set_b
  ),

  -- Bring manager_category and first_name back (one row per call_center)
  manager_info AS (
    SELECT DISTINCT
      cs_call_center_sk,
      manager_category,
      first_name
    FROM joined
  )
SELECT
  a.cs_call_center_sk,
  c.cc_name,
  a.rating,
  a.total_sales,
  a.total_qty,
  a.txn_count,
  a.avg_tax,
  a.high_tax_sales,
  mi.manager_category,
  mi.first_name
FROM agg_sales a
JOIN call_center c
  ON a.cs_call_center_sk = c.cc_call_center_sk
JOIN manager_info mi
  ON a.cs_call_center_sk = mi.cs_call_center_sk
JOIN key_diff kd
  ON a.cs_call_center_sk = kd.cs_sk
WHERE a.cs_call_center_sk IN (SELECT cc_call_center_sk FROM no_big_sales)
ORDER BY a.total_sales DESC
LIMIT 100
