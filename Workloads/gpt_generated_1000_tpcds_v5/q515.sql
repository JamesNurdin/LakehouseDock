WITH base AS (
    SELECT
        cp.cp_department,
        hd.hd_buy_potential,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_size_category,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_department = 'Electronics'
        AND cp.cp_catalog_page_number BETWEEN 5 AND 15
        AND hd.hd_buy_potential IN ('>10000', '5001-1000')
        AND ib.ib_lower_bound >= 30000
        AND cr.cr_return_amount > 20
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'Online'
        )
),
agg1 AS (
    SELECT
        cp_department,
        hd_buy_potential,
        return_size_category,
        SUM(cr_return_quantity) AS total_qty,
        SUM(cr_return_amount)   AS total_amount,
        SUM(cr_net_loss)        AS total_net_loss
    FROM base
    GROUP BY ROLLUP (cp_department, hd_buy_potential, return_size_category)
)
SELECT
    cp_department,
    AVG(total_net_loss) AS avg_net_loss,
    COUNT(*)          AS grp_row_cnt
FROM agg1
WHERE hd_buy_potential IS NOT NULL -- keep only detail rows, exclude rolled‑up subtotals
GROUP BY cp_department
ORDER BY avg_net_loss DESC
LIMIT 100
