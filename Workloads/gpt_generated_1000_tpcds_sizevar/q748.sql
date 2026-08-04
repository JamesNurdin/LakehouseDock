WITH
  store_agg AS (
    SELECT ss_store_sk,
           ss_item_sk,
           SUM(ss_quantity)           AS store_qty,
           SUM(ss_net_paid)           AS store_net_paid
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
  ),
  catalog_agg AS (
    SELECT cs_catalog_page_sk,
           cs_item_sk,
           SUM(cs_quantity)          AS catalog_qty,
           SUM(cs_net_paid_inc_tax)  AS catalog_net_paid
    FROM catalog_sales
    GROUP BY cs_catalog_page_sk, cs_item_sk
  ),
  combined_sales AS (
    SELECT ss_store_sk                     AS store_sk,
           ss_item_sk                      AS item_sk,
           store_qty                       AS qty,
           store_net_paid                  AS net_paid,
           NULL                            AS catalog_page_sk
    FROM store_agg
    UNION
    SELECT NULL                           AS store_sk,
           cs_item_sk                      AS item_sk,
           catalog_qty                     AS qty,
           catalog_net_paid                AS net_paid,
           cs_catalog_page_sk              AS catalog_page_sk
    FROM catalog_agg
  ),
  web_return_items AS (
    SELECT DISTINCT wr_item_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),
  store_items_excluding_catalog AS (
    SELECT i.i_item_id
    FROM item i
    JOIN store_agg sa ON i.i_item_sk = sa.ss_item_sk
    EXCEPT
    SELECT i2.i_item_id
    FROM item i2
    JOIN catalog_agg ca ON i2.i_item_sk = ca.cs_item_sk
  ),
  store_and_web_intersect AS (
    SELECT i.i_item_id
    FROM item i
    JOIN store_agg sa ON i.i_item_sk = sa.ss_item_sk
    INTERSECT
    SELECT i3.i_item_id
    FROM item i3
    JOIN web_return_items wri ON i3.i_item_sk = wri.wr_item_sk
  )
SELECT
  s.s_state,
  i.i_brand,
  cp.cp_department,
  wp.wp_autogen_flag,
  SUM(cs.qty)                                 AS total_qty,
  SUM(cs.net_paid)                            AS total_net_paid,
  RANK() OVER (PARTITION BY s.s_state ORDER BY SUM(cs.net_paid) DESC) AS state_rank,
  COUNT(DISTINCT i.i_item_id)                 AS distinct_items_sold,
  (SELECT COUNT(*) FROM store_items_excluding_catalog) AS excl_item_count,
  (SELECT COUNT(*) FROM store_and_web_intersect)       AS intersect_item_count
FROM combined_sales cs
LEFT JOIN item i               ON cs.item_sk = i.i_item_sk
LEFT JOIN store s              ON cs.store_sk = s.s_store_sk
LEFT JOIN catalog_page cp      ON cs.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_returns wr       ON i.i_item_sk = wr.wr_item_sk
LEFT JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cp.cp_department = 'Books'
  AND i.i_brand = 'Brand#12'
  AND s.s_state = 'CA'
  AND wp.wp_autogen_flag = 'Y'
  AND cs.net_paid > 1000
GROUP BY CUBE (s.s_state, i.i_brand, cp.cp_department, wp.wp_autogen_flag)
HAVING SUM(cs.qty) > 0
LIMIT 100
