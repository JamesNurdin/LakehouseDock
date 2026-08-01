WITH
  cs_data AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_ship_mode_sk,
      i.i_brand_id,
      i.i_category_id,
      sm.sm_type,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (2002002, 8015002)
      AND sm.sm_type IN ('NEXT DAY', 'EXPRESS')
      AND cs.cs_quantity > 5
      AND cs.cs_net_paid > 100.00
      AND i.i_rec_start_date >= DATE '1999-01-01'
  ),
  ws_data AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_ship_mode_sk,
      i.i_brand_id,
      i.i_category_id,
      sm.sm_type,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (2002002, 8015002)
      AND sm.sm_type IN ('NEXT DAY', 'EXPRESS')
      AND ws.ws_quantity > 5
      AND ws.ws_net_paid > 100.00
      AND i.i_rec_start_date >= DATE '1999-01-01'
  ),
  intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM cs_data
    INTERSECT
    SELECT ws_item_sk FROM ws_data
  ),
  union_agg AS (
    SELECT
      cs_item_sk AS item_sk,
      cs_ship_mode_sk AS ship_mode_sk,
      SUM(cs.cs_net_paid) AS total_net_paid,
      'catalog' AS src
    FROM cs_data cs
    GROUP BY GROUPING SETS ((cs_item_sk, cs_ship_mode_sk), (cs_item_sk), (cs_ship_mode_sk), ())
    UNION
    SELECT
      ws_item_sk AS item_sk,
      ws_ship_mode_sk AS ship_mode_sk,
      SUM(ws.ws_net_paid) AS total_net_paid,
      'web' AS src
    FROM ws_data ws
    GROUP BY GROUPING SETS ((ws_item_sk, ws_ship_mode_sk), (ws_item_sk), (ws_ship_mode_sk), ())
  ),
  full_joined AS (
    SELECT
      COALESCE(c.cs_item_sk, w.ws_item_sk) AS item_sk,
      COALESCE(c.cs_ship_mode_sk, w.ws_ship_mode_sk) AS ship_mode_sk,
      c.cs_quantity,
      w.ws_quantity,
      c.cs_net_paid,
      w.ws_net_paid
    FROM cs_data c
    FULL OUTER JOIN ws_data w
      ON c.cs_item_sk = w.ws_item_sk
     AND c.cs_ship_mode_sk = w.ws_ship_mode_sk
  )
SELECT
  fj.item_sk,
  fj.ship_mode_sk,
  SUM(COALESCE(fj.cs_net_paid, 0) + COALESCE(fj.ws_net_paid, 0)) AS combined_net_paid,
  COUNT(*) AS rows_per_group,
  MAX(CASE WHEN EXISTS (SELECT 1 FROM intersect_items ii WHERE ii.item_sk = fj.item_sk) THEN 1 ELSE 0 END) AS both_side_flag
FROM full_joined fj
WHERE (fj.cs_quantity > 5 OR fj.ws_quantity > 5)
GROUP BY GROUPING SETS ((fj.item_sk, fj.ship_mode_sk), (fj.item_sk), (fj.ship_mode_sk), ())
HAVING SUM(COALESCE(fj.cs_net_paid, 0) + COALESCE(fj.ws_net_paid, 0)) > (
    SELECT AVG(total_net_paid) FROM union_agg
)
ORDER BY combined_net_paid DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
