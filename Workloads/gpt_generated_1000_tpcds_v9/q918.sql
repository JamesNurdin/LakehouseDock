WITH filtered AS (
    SELECT
        cr.cr_ship_mode_sk,
        sm.sm_carrier,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_refunded_cash,
        cr.cr_store_credit,
        cr.cr_fee,
        CASE
            WHEN cr.cr_return_amount > 500 THEN 'High'
            WHEN cr.cr_return_amount > 200 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM catalog_returns cr
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_quantity >= 1
      AND cr.cr_return_amount >= 100
      AND sm.sm_carrier = 'FEDEX'
)

SELECT
    dim1,
    dim2,
    total_return_amount,
    avg_return_amount,
    cnt_returns,
    sum_high_return_amount,
    min_return_amount,
    max_return_amount
FROM (
    SELECT
        sm_carrier AS dim1,
        CAST(cr_ship_mode_sk AS VARCHAR) AS dim2,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN cr_return_amount > 500 THEN cr_return_amount ELSE 0 END) AS sum_high_return_amount,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM filtered
    GROUP BY GROUPING SETS (
        (sm_carrier, cr_ship_mode_sk),
        (sm_carrier),
        (cr_ship_mode_sk),
        ()
    )
) AS agg_carrier_ship

UNION ALL

SELECT
    dim1,
    dim2,
    total_return_amount,
    avg_return_amount,
    cnt_returns,
    sum_high_return_amount,
    min_return_amount,
    max_return_amount
FROM (
    SELECT
        return_category AS dim1,
        CAST(NULL AS VARCHAR) AS dim2,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN cr_return_amount > 500 THEN cr_return_amount ELSE 0 END) AS sum_high_return_amount,
        MIN(cr_return_amount) AS min_return_amount,
        MAX(cr_return_amount) AS max_return_amount
    FROM filtered
    GROUP BY return_category
) AS agg_category
ORDER BY total_return_amount DESC
LIMIT 100
