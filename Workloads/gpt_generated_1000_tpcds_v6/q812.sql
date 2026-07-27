WITH filtered_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_store_credit,
        cr.cr_return_tax,
        cr.cr_order_number,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk
    FROM
        catalog_returns cr
    WHERE
        cr.cr_return_amount > 100
        AND cr.cr_return_quantity >= 2
        AND cr.cr_store_credit BETWEEN 10 AND 200
        AND cr.cr_return_tax IS NOT NULL
        AND cr.cr_return_quantity IS NOT NULL
        AND cr.cr_return_amount IS NOT NULL
) 
SELECT
    w.w_warehouse_name,
    w.w_state AS warehouse_state,
    cd.cd_education_status,
    COALESCE(ca.ca_state, 'UNKNOWN') AS customer_state,
    hd.hd_buy_potential,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_orders,
    MIN(fr.cr_return_quantity) AS min_quantity,
    MAX(fr.cr_return_quantity) AS max_quantity
FROM
    filtered_returns fr
    INNER JOIN warehouse w
        ON fr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd
        ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT OUTER JOIN customer_address ca
        ON fr.cr_refunded_addr_sk = ca.ca_address_sk
    INNER JOIN household_demographics hd
        ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE
    cd.cd_education_status IN ('4 yr Degree', 'Advanced Degree')
    AND ca.ca_state = 'CA'
    AND w.w_state = 'TX'
    AND hd.hd_income_band_sk IN (3, 4, 5)
GROUP BY
    w.w_warehouse_name,
    w.w_state,
    cd.cd_education_status,
    COALESCE(ca.ca_state, 'UNKNOWN'),
    hd.hd_buy_potential
HAVING
    SUM(fr.cr_return_amount) > 5000
    AND COUNT(DISTINCT fr.cr_order_number) >= 5
ORDER BY
    total_return_amount DESC
LIMIT 100
