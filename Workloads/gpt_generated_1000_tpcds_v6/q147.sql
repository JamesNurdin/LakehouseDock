WITH filtered_returns AS (
    SELECT
        cr.cr_return_amt_inc_tax,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_cdemo_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        sm.sm_carrier,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_catalog_number IN (10, 13)
      AND cp.cp_end_date_sk BETWEEN 2451000 AND 2451500
      AND cr.cr_return_amt_inc_tax > 1000
      AND cd.cd_credit_rating = 'Good'
)
SELECT
    fr.cp_department,
    fr.sm_carrier,
    fr.cd_gender,
    SUM(fr.cr_return_amt_inc_tax) AS total_return_amount,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_return_orders,
    MIN(fr.cr_return_quantity) AS min_return_qty,
    MAX(fr.cr_return_quantity) AS max_return_qty,
    SUM(CASE WHEN fr.cr_return_amt_inc_tax > 2000 THEN fr.cr_return_amt_inc_tax ELSE 0 END) AS high_value_return_sum,
    CASE
        WHEN SUM(fr.cr_return_amt_inc_tax) > (
            SELECT AVG(cr2.cr_return_amt_inc_tax)
            FROM catalog_returns cr2
        ) THEN 'Above Avg Total'
        ELSE 'Below Avg Total'
    END AS total_return_category
FROM filtered_returns fr
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = fr.cd_demo_sk
   AND ws.ws_ship_mode_sk = fr.cr_ship_mode_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_ship_mode_sk = fr.cr_ship_mode_sk
      AND ws2.ws_quantity > 10
)
GROUP BY fr.cp_department, fr.sm_carrier, fr.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
