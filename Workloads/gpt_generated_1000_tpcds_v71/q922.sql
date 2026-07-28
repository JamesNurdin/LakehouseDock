/*
Goal: Identify catalog pages and shipping modes that generate the highest return amounts, enriched with household demographics and average web‑return metrics. The query aggregates returns, applies multiple filters, uses a scalar sub‑query, includes DISTINCT logic, creates subtotals with GROUPING SETS, and ranks catalog pages by total return amount.
*/
WITH wr_agg AS (
    SELECT
        hd.hd_demo_sk,
        AVG(wr.wr_return_amt)          AS avg_web_return_amt,
        COUNT(*)                       AS web_return_cnt
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2451300
    GROUP BY hd.hd_demo_sk
),
cr_base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        sm.sm_type,
        sm.sm_carrier,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        hd_ref.hd_income_band_sk,
        hd_ref.hd_vehicle_count,
        wa.avg_web_return_amt,
        wa.web_return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN wr_agg wa
        ON hd_ref.hd_demo_sk = wa.hd_demo_sk
    WHERE cp.cp_catalog_number IN (1, 10, 12, 13)
      AND sm.sm_type IN ('OVERNIGHT', 'NEXT DAY', 'EXPRESS')
      AND cr.cr_return_amount > 50
      AND cr.cr_returned_date_sk BETWEEN 2450800 AND 2451300
)
SELECT
    cp_catalog_page_id,
    cp_catalog_number,
    sm_type,
    sm_carrier,
    hd_income_band_sk,
    hd_vehicle_count,
    SUM(cr_return_amount)                         AS total_return_amount,
    AVG(cr_return_quantity)                       AS avg_return_quantity,
    MAX(avg_web_return_amt)                       AS max_avg_web_return,
    MAX(web_return_cnt)                           AS max_web_return_cnt,
    CASE
        WHEN SUM(cr_return_amount) > 500 THEN 'HIGH'
        WHEN SUM(cr_return_amount) BETWEEN 200 AND 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                          AS amount_category,
    ROW_NUMBER() OVER (PARTITION BY cp_catalog_number ORDER BY SUM(cr_return_amount) DESC) AS rn
FROM cr_base
GROUP BY GROUPING SETS (
    (cp_catalog_page_id, cp_catalog_number, sm_type, sm_carrier, hd_income_band_sk, hd_vehicle_count),
    (cp_catalog_number, sm_type),
    ()
)
HAVING COUNT(DISTINCT sm_type) > 0
ORDER BY cp_catalog_number, rn
LIMIT 100
