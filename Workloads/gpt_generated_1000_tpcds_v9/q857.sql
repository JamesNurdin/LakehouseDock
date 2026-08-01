WITH sr_agg AS (
    SELECT
        'store' AS return_type,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        MIN(sr.sr_return_quantity) AS min_return_qty,
        MAX(sr.sr_return_quantity) AS max_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
cr_agg AS (
    SELECT
        'catalog' AS return_type,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        MIN(cr.cr_return_quantity) AS min_return_qty,
        MAX(cr.cr_return_quantity) AS max_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ib.ib_upper_bound >= 150000
      AND hd_refunded.hd_dep_count >= 4
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
wr_agg AS (
    SELECT
        'web' AS return_type,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        MIN(wr.wr_return_quantity) AS min_return_qty,
        MAX(wr.wr_return_quantity) AS max_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    WHERE d.d_year = 2001
      AND cd_refunded.cd_purchase_estimate > 5000
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    return_type,
    d_year,
    d_month_seq,
    total_net_loss,
    return_count,
    avg_return_qty,
    min_return_qty,
    max_return_qty
FROM (
    SELECT return_type, d_year, d_month_seq, total_net_loss, return_count, avg_return_qty, min_return_qty, max_return_qty
    FROM sr_agg
    UNION ALL
    SELECT return_type, d_year, d_month_seq, total_net_loss, return_count, avg_return_qty, min_return_qty, max_return_qty
    FROM cr_agg
) 
EXCEPT
SELECT return_type, d_year, d_month_seq, total_net_loss, return_count, avg_return_qty, min_return_qty, max_return_qty
FROM wr_agg
ORDER BY d_year, d_month_seq, return_type
LIMIT 100
