WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        r.r_reason_desc,
        cust.c_salutation
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)^damaged')
      AND sm.sm_carrier LIKE '%AIR%'
      AND cust.c_salutation LIKE 'Mr.%'
)
SELECT
    concat(cc.cc_name, ' - ', sm2.sm_carrier) AS call_center_carrier,
    regexp_extract(fr.r_reason_desc, '^([A-Za-z]+)') AS reason_root,
    COUNT(*) AS returns_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    CASE
        WHEN AVG(fr.cr_return_amount) > (SELECT avg(cr_return_amount) FROM catalog_returns)
        THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level
FROM filtered_returns fr
JOIN call_center cc
    ON fr.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm2
    ON fr.cs_ship_mode_sk = sm2.sm_ship_mode_sk
GROUP BY
    cc.cc_name,
    sm2.sm_carrier,
    fr.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
