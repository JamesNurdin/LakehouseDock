WITH store_agg AS (
    SELECT
        i.i_category AS category,
        hd.hd_vehicle_count AS vehicle_count,
        SUM(sr.sr_net_loss) AS store_net_loss,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_category, hd.hd_vehicle_count
),
catalog_agg AS (
    SELECT
        i.i_category AS category,
        hd.hd_vehicle_count AS vehicle_count,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY i.i_category, hd.hd_vehicle_count
)
SELECT
    COALESCE(s.category, c.category) AS category,
    COALESCE(s.vehicle_count, c.vehicle_count) AS vehicle_count,
    s.store_net_loss,
    c.catalog_net_loss,
    (COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0)) AS total_net_loss,
    s.avg_store_return_qty,
    c.avg_catalog_return_qty,
    (s.store_net_loss - c.catalog_net_loss) / NULLIF(c.catalog_net_loss, 0) AS net_loss_diff_ratio,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0)) DESC) AS loss_rank
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.category = c.category
   AND s.vehicle_count = c.vehicle_count
WHERE (COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
