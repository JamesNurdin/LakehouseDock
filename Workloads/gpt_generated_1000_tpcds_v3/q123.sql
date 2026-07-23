WITH avg_center_returns AS (
    SELECT
        cr.cr_call_center_sk,
        avg(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_division_name,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    c_ret.c_customer_id,
    c_ret.c_first_name,
    c_ret.c_last_name,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_return_tax,
    cr.cr_net_loss,
    CASE
        WHEN cr.cr_return_amount > 500 THEN 'High'
        ELSE 'Low'
    END AS return_amount_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cr.cr_return_amount DESC) AS rn_return_center,
    ac.avg_return_amount,
    CASE
        WHEN cr.cr_return_amount > ac.avg_return_amount THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_vs_center_avg,
    (SELECT max(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk) AS max_center_return_amount
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
LEFT JOIN avg_center_returns ac
    ON cr.cr_call_center_sk = ac.cr_call_center_sk
WHERE
    cc.cc_division_name = 'anti'
    AND cc.cc_gmt_offset >= 0
    AND cp.cp_catalog_number BETWEEN 100 AND 200
    AND cp.cp_type = 'Web'
    AND cr.cr_return_amount > 100.00
    AND cr.cr_return_ship_cost > 10.00
    AND cr.cr_reversed_charge < 500.00
    AND c_ret.c_birth_year BETWEEN 1970 AND 1995
    AND c_ret.c_customer_id LIKE 'AAAA%'
ORDER BY rn_return_center, cr.cr_return_amount DESC
LIMIT 100
