WITH return_agg AS (
    SELECT
        cp.cp_catalog_number AS catalog_number,
        cp.cp_type AS type,
        hd_refunded.hd_income_band_sk AS refunded_income_band,
        hd_returning.hd_income_band_sk AS returning_income_band,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_reversed_charge) AS avg_rev_charge
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    WHERE cp.cp_end_date_sk BETWEEN 2451000 AND 2451500
      AND cp.cp_type = 'monthly'
      AND cr.cr_reversed_charge > 100
      AND hd_refunded.hd_income_band_sk IN (9, 10, 13)
    GROUP BY
        cp.cp_catalog_number,
        cp.cp_type,
        hd_refunded.hd_income_band_sk,
        hd_returning.hd_income_band_sk
)
SELECT
    catalog_number,
    type,
    AVG(total_return_amount) AS avg_total_return_amount,
    SUM(total_return_qty) AS sum_return_qty
FROM return_agg
GROUP BY catalog_number, type
HAVING AVG(total_return_amount) > 500
ORDER BY avg_total_return_amount DESC
LIMIT 100
