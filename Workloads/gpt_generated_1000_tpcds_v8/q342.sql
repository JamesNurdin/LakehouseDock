WITH
  /* Combine catalog and web sales with a full outer join */
  full_sales AS (
    SELECT
      COALESCE(cs.cs_item_sk, ws.ws_item_sk) AS item_sk,
      cs.cs_net_paid               AS catalog_net_paid,
      ws.ws_net_paid               AS web_net_paid
    FROM (
           SELECT cs_item_sk, cs_net_paid
           FROM catalog_sales
           WHERE cs_net_paid > 500
         ) cs
    FULL OUTER JOIN (
           SELECT ws_item_sk, ws_net_paid
           FROM web_sales
           WHERE ws_net_paid > 500
         ) ws
      ON cs.cs_item_sk = ws.ws_item_sk
  ),
  /* Aggregate the full‑outer‑joined data; use ROLLUP to get an overall subtotal */
  agg_catalog_web AS (
    SELECT
      i.i_item_id,
      SUM(COALESCE(fs.catalog_net_paid, 0) + COALESCE(fs.web_net_paid, 0)) AS total_net_paid,
      SUM(CASE WHEN fs.catalog_net_paid IS NOT NULL THEN 1 ELSE 0 END) AS cnt_catalog,
      SUM(CASE WHEN fs.web_net_paid IS NOT NULL THEN 1 ELSE 0 END) AS cnt_web
    FROM full_sales fs
    JOIN item i ON fs.item_sk = i.i_item_sk
    WHERE EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
              AND p.p_discount_active = 'Y'
          )
    GROUP BY ROLLUP(i.i_item_id)
  ),
  first_part AS (
    SELECT
      i_item_id,
      total_net_paid,
      CASE
        WHEN i_item_id IS NULL THEN 'All'
        WHEN cnt_catalog > 0 AND cnt_web > 0 THEN 'Both'
        WHEN cnt_catalog > 0 THEN 'CatalogOnly'
        WHEN cnt_web > 0 THEN 'WebOnly'
        ELSE 'None'
      END AS sales_channel
    FROM agg_catalog_web
  ),
  /* Store‑sales aggregation with ROLLUP, also filtered by a promotion existence check */
  store_agg AS (
    SELECT
      i2.i_item_id,
      SUM(ss2.ss_net_paid) AS total_net_paid,
      COUNT(*)               AS cnt_store
    FROM store_sales ss2
    JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
    WHERE ss2.ss_net_paid > 300
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i2.i_item_sk
              AND p2.p_discount_active = 'Y'
          )
    GROUP BY ROLLUP(i2.i_item_id)
  ),
  second_part AS (
    SELECT
      i_item_id,
      total_net_paid,
      CASE WHEN i_item_id IS NULL THEN 'All' ELSE 'Store' END AS sales_channel
    FROM store_agg
  )
SELECT i_item_id,
       total_net_paid,
       sales_channel
FROM first_part
UNION
SELECT i_item_id,
       total_net_paid,
       sales_channel
FROM second_part
ORDER BY total_net_paid DESC
LIMIT 100
