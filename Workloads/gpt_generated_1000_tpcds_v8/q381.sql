WITH
    cat_ret AS (
        SELECT cr.cr_item_sk,
               SUM(cr.cr_net_loss)          AS cat_net_loss,
               COUNT(*)                     AS cat_ret_cnt
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE r.r_reason_desc LIKE '%duplicate%'
        GROUP BY cr.cr_item_sk
    ),
    store_ret AS (
        SELECT sr.sr_item_sk,
               SUM(sr.sr_net_loss)          AS store_net_loss,
               COUNT(*)                     AS store_ret_cnt
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'M'
          AND r.r_reason_id = 'AAAAAAAABAAAAAAA'
        GROUP BY sr.sr_item_sk
    ),
    intersect_items AS (
        SELECT cr_item_sk AS item_sk FROM cat_ret
        INTERSECT
        SELECT sr_item_sk FROM store_ret
    ),
    filtered_items AS (
        SELECT i.item_sk
        FROM intersect_items i
        WHERE i.item_sk NOT IN (
                  SELECT DISTINCT cr_item_sk
                  FROM catalog_returns
                  WHERE cr_net_loss > 1000
              )
          AND NOT EXISTS (
                  SELECT 1
                  FROM web_returns wr
                  WHERE wr.wr_item_sk = i.item_sk
              )
    )
SELECT
    fi.item_sk,
    cr.cat_net_loss,
    sr.store_net_loss,
    (
        SELECT SUM(cr3.cr_return_quantity)
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = fi.item_sk
    )                                     AS total_return_qty,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = fi.item_sk
    )                                     AS web_return_count
FROM filtered_items fi
JOIN cat_ret cr ON cr.cr_item_sk = fi.item_sk
JOIN store_ret sr ON sr.sr_item_sk = fi.item_sk
ORDER BY cr.cat_net_loss DESC, sr.store_net_loss DESC
LIMIT 100
