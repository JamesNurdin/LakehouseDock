WITH
    refunded AS (
        SELECT
            hd.hd_demo_sk,
            'refunded' AS household_type,
            SUM(cr.cr_net_loss) AS total_net_loss,
            SUM(cr.cr_reversed_charge) AS total_rev_charge,
            COUNT(*) AS return_cnt,
            (
                SELECT AVG(cr2.cr_return_quantity)
                FROM catalog_returns cr2
                WHERE cr2.cr_refunded_hdemo_sk = hd.hd_demo_sk
            ) AS avg_return_qty,
            SUM(metric) AS total_demo_metric
        FROM catalog_returns cr TABLESAMPLE BERNOULLI (10)
        JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        CROSS JOIN UNNEST(ARRAY[hd.hd_dep_count, hd.hd_vehicle_count]) AS t(metric)
        WHERE cr.cr_net_loss > 500
        GROUP BY ROLLUP (hd.hd_demo_sk)
    ),
    returning AS (
        SELECT
            hd.hd_demo_sk,
            'returning' AS household_type,
            SUM(cr.cr_net_loss) AS total_net_loss,
            SUM(cr.cr_reversed_charge) AS total_rev_charge,
            COUNT(*) AS return_cnt,
            (
                SELECT AVG(cr2.cr_return_quantity)
                FROM catalog_returns cr2
                WHERE cr2.cr_returning_hdemo_sk = hd.hd_demo_sk
            ) AS avg_return_qty,
            SUM(metric) AS total_demo_metric
        FROM catalog_returns cr TABLESAMPLE BERNOULLI (10)
        JOIN household_demographics hd
            ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
        CROSS JOIN UNNEST(ARRAY[hd.hd_dep_count, hd.hd_vehicle_count]) AS t(metric)
        WHERE cr.cr_net_loss > 500
        GROUP BY ROLLUP (hd.hd_demo_sk)
    ),
    combined_full AS (
        SELECT
            COALESCE(rf.hd_demo_sk, rt.hd_demo_sk) AS hd_demo_sk,
            'combined' AS household_type,
            COALESCE(rf.total_net_loss, 0) + COALESCE(rt.total_net_loss, 0) AS total_net_loss,
            COALESCE(rf.total_rev_charge, 0) + COALESCE(rt.total_rev_charge, 0) AS total_rev_charge,
            COALESCE(rf.return_cnt, 0) + COALESCE(rt.return_cnt, 0) AS return_cnt,
            COALESCE(rf.avg_return_qty, 0) + COALESCE(rt.avg_return_qty, 0) AS avg_return_qty,
            COALESCE(rf.total_demo_metric, 0) + COALESCE(rt.total_demo_metric, 0) AS total_demo_metric
        FROM refunded rf
        FULL OUTER JOIN returning rt
            ON rf.hd_demo_sk = rt.hd_demo_sk
    )
SELECT
    hd_demo_sk,
    household_type,
    total_net_loss,
    total_rev_charge,
    return_cnt,
    avg_return_qty,
    total_demo_metric
FROM refunded
UNION DISTINCT
SELECT
    hd_demo_sk,
    household_type,
    total_net_loss,
    total_rev_charge,
    return_cnt,
    avg_return_qty,
    total_demo_metric
FROM returning
UNION DISTINCT
SELECT
    hd_demo_sk,
    household_type,
    total_net_loss,
    total_rev_charge,
    return_cnt,
    avg_return_qty,
    total_demo_metric
FROM combined_full
ORDER BY
    hd_demo_sk ASC NULLS LAST,
    household_type
