WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_manufact,
           i_product_name,
           i_brand
    FROM   item
    WHERE  regexp_like(i_manufact, '^a.*')      -- manufacturer starts with 'a'
      AND  i_product_name LIKE '%Pro%'          -- product name contains the word "Pro"
),
store_agg AS (
    SELECT sr.sr_item_sk AS item_sk,
           COUNT(*)                           AS store_return_cnt,
           SUM(sr.sr_net_loss)                AS store_net_loss,
           AVG(sr.sr_return_amt)              AS avg_store_return_amt
    FROM   store_returns sr
    JOIN   filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
    GROUP BY sr.sr_item_sk
),
web_agg AS (
    SELECT wr.wr_item_sk AS item_sk,
           COUNT(*)                           AS web_return_cnt,
           SUM(wr.wr_net_loss)                AS web_net_loss,
           AVG(wr.wr_return_amt)              AS avg_web_return_amt
    FROM   web_returns wr
    JOIN   filtered_items fi ON wr.wr_item_sk = fi.i_item_sk
    GROUP BY wr.wr_item_sk
),
combined AS (
    SELECT fi.i_item_sk,
           fi.i_category,
           fi.i_manufact,
           fi.i_product_name,
           fi.i_brand,
           COALESCE(sa.store_return_cnt, 0)      AS store_return_cnt,
           COALESCE(sa.store_net_loss, 0)       AS store_net_loss,
           COALESCE(wa.web_return_cnt, 0)       AS web_return_cnt,
           COALESCE(wa.web_net_loss, 0)         AS web_net_loss,
           COALESCE(sa.avg_store_return_amt, 0) AS avg_store_return_amt,
           COALESCE(wa.avg_web_return_amt, 0)   AS avg_web_return_amt,
           CONCAT(fi.i_brand, ' ', fi.i_product_name) AS full_name
    FROM   filtered_items fi
    LEFT JOIN store_agg sa ON sa.item_sk = fi.i_item_sk
    LEFT JOIN web_agg   wa ON wa.item_sk = fi.i_item_sk
    WHERE  EXISTS (
               SELECT 1
               FROM   web_returns wr_sub
               WHERE  wr_sub.wr_item_sk = fi.i_item_sk
               AND    wr_sub.wr_return_quantity > 5   -- at least one web return with qty > 5
           )
)
SELECT
    c.i_category                                      AS category,
    COUNT(*)                                          AS item_count,
    SUM(c.store_net_loss)                             AS total_store_net_loss,
    SUM(c.web_net_loss)                               AS total_web_net_loss,
    SUM(c.store_net_loss + c.web_net_loss)           AS total_combined_net_loss,
    AVG(c.avg_store_return_amt)                       AS avg_store_return_amt,
    AVG(c.avg_web_return_amt)                         AS avg_web_return_amt,
    MAX(c.full_name) FILTER (WHERE regexp_extract(c.i_manufact, '(cally)') IS NOT NULL) AS example_full_name
FROM   combined c
GROUP BY c.i_category
ORDER BY total_combined_net_loss DESC
LIMIT 10
