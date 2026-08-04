-- Goal: Compare monthly net loss from catalog returns and store returns for the year 2001, list distinct catalog items returned per month, flag months with any high‑loss catalog return, and combine catalog‑only and store‑only months using a UNION ALL. The query uses CTEs, a FULL OUTER JOIN, a LATERAL subquery, scalar subqueries, and limits the output.
WITH catalog_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
store_month AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
full_summary AS (
    SELECT
        COALESCE(cm.month, sm.month) AS month,
        cm.catalog_net_loss,
        sm.store_net_loss
    FROM catalog_month cm
    FULL OUTER JOIN store_month sm ON cm.month = sm.month
)
SELECT
    fs.month,
    fs.catalog_net_loss,
    fs.store_net_loss,
    lt.distinct_catalog_items,
    EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        JOIN customer c3 ON cr3.cr_refunded_customer_sk = c3.c_customer_sk
        JOIN date_dim d3 ON cr3.cr_returned_date_sk = d3.d_date_sk
        WHERE d3.d_month_seq = fs.month
          AND cr3.cr_net_loss > 1000
    ) AS has_high_loss
FROM (
    SELECT fs.month, fs.catalog_net_loss, fs.store_net_loss
    FROM full_summary fs
    WHERE fs.catalog_net_loss IS NOT NULL
    UNION ALL
    SELECT fs.month, fs.catalog_net_loss, fs.store_net_loss
    FROM full_summary fs
    WHERE fs.store_net_loss IS NOT NULL
) AS fs
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT cr2.cr_item_sk) AS distinct_catalog_items
    FROM catalog_returns cr2
    JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_month_seq = fs.month
) AS lt
ORDER BY fs.month
LIMIT 100
