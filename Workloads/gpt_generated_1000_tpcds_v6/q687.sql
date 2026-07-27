WITH filtered AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        cr.cr_return_amt_inc_tax,
        i.i_brand,
        i.i_category,
        i.i_formulation,
        i.i_manufact,
        i.i_container,
        sm.sm_type,
        sm.sm_code,
        sm.sm_carrier
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_formulation = '452645olive281530722'
      AND i.i_manufact = 'barprically'
      AND i.i_container = 'Unknown'
      AND cr.cr_refunded_cash > 20.00
      AND cr.cr_return_amount >= 100.00
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND sm.sm_code = 'AIR'
      AND sm.sm_carrier = 'FEDEX'
)
SELECT
    i_brand,
    i_category,
    sm_type,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    MIN(cr_return_amt_inc_tax) AS min_inc_tax,
    MAX(cr_return_amt_inc_tax) AS max_inc_tax,
    CASE
        WHEN SUM(cr_return_amount) > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_level
FROM filtered
GROUP BY
    i_brand,
    i_category,
    sm_type
ORDER BY
    total_return_amount DESC,
    return_cnt DESC
LIMIT 100
