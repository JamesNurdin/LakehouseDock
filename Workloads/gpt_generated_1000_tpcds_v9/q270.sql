WITH
store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT sr.sr_reason_sk) AS store_distinct_reasons
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((i.i_item_id, d.d_year), (i.i_item_id), (d.d_year))
),
catalog_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(DISTINCT cr.cr_reason_sk) AS catalog_distinct_reasons
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((i.i_item_id, d.d_year), (i.i_item_id), (d.d_year))
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT wr.wr_reason_sk) AS web_distinct_reasons
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS ((i.i_item_id, d.d_year), (i.i_item_id), (d.d_year))
),
combined_returns AS (
    SELECT
        item_id,
        year,
        store_return_qty AS return_qty,
        store_net_loss AS net_loss,
        store_distinct_reasons AS distinct_reasons,
        'store' AS source
    FROM store_agg
    UNION ALL
    SELECT
        item_id,
        year,
        web_return_qty AS return_qty,
        web_net_loss AS net_loss,
        web_distinct_reasons AS distinct_reasons,
        'web' AS source
    FROM web_agg
)

SELECT DISTINCT
    COALESCE(cr.item_id, cr2.item_id) AS item_id,
    COALESCE(cr.year, cr2.year) AS year,
    cr.catalog_return_qty,
    cr2.return_qty,
    cr.catalog_net_loss,
    cr2.net_loss,
    cr.catalog_distinct_reasons,
    cr2.distinct_reasons,
    (
        SELECT SUM(ca.catalog_return_qty)
        FROM catalog_agg ca
        WHERE ca.item_id = COALESCE(cr.item_id, cr2.item_id)
    ) AS total_catalog_qty_all_years
FROM catalog_agg cr
FULL OUTER JOIN combined_returns cr2
    ON cr.item_id = cr2.item_id
   AND cr.year = cr2.year
WHERE (cr.catalog_net_loss > 0 OR cr2.net_loss > 0)
ORDER BY item_id, year
LIMIT 100
