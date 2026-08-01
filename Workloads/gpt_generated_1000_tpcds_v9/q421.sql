WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_product_name,
           i_category
    FROM tpcds.item
    WHERE i_rec_start_date <= DATE '2002-01-01'
      AND i_rec_end_date   >= DATE '2002-01-01'
),
store_agg AS (
    SELECT
        fi.i_item_id,
        fi.i_product_name,
        'Store'   AS return_source,
        CASE
            WHEN sr.sr_net_loss > 1000 THEN 'HIGH'
            WHEN sr.sr_net_loss > 100  THEN 'MEDIUM'
            ELSE 'LOW'
        END       AS loss_category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*)            AS return_cnt
    FROM tpcds.store_returns sr
    JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
    LEFT JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE (r.r_reason_desc = 'Did not like the color' OR r.r_reason_desc IS NULL)
    GROUP BY fi.i_item_id,
             fi.i_product_name,
             CASE
                 WHEN sr.sr_net_loss > 1000 THEN 'HIGH'
                 WHEN sr.sr_net_loss > 100  THEN 'MEDIUM'
                 ELSE 'LOW'
             END
),
catalog_agg AS (
    SELECT
        fi.i_item_id,
        fi.i_product_name,
        'Catalog' AS return_source,
        CASE
            WHEN cr.cr_net_loss > 1000 THEN 'HIGH'
            WHEN cr.cr_net_loss > 100  THEN 'MEDIUM'
            ELSE 'LOW'
        END       AS loss_category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*)            AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
    LEFT JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE (r.r_reason_desc = 'Did not like the color' OR r.r_reason_desc IS NULL)
    GROUP BY fi.i_item_id,
             fi.i_product_name,
             CASE
                 WHEN cr.cr_net_loss > 1000 THEN 'HIGH'
                 WHEN cr.cr_net_loss > 100  THEN 'MEDIUM'
                 ELSE 'LOW'
             END
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT
    i_item_id,
    i_product_name,
    return_source,
    loss_category,
    total_net_loss,
    return_cnt
FROM combined
ORDER BY total_net_loss DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY
