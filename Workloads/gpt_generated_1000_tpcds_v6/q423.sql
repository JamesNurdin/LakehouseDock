WITH warehouse_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    rr.total_return_amount,
    rr.return_cnt,
    r.r_reason_desc,
    d.d_year,
    p.p_promo_name
FROM warehouse_returns rr
JOIN warehouse w
    ON rr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN customer cu_refunded
    ON cr.cr_refunded_customer_sk = cu_refunded.c_customer_sk
LEFT JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer cu_returning
    ON cr.cr_returning_customer_sk = cu_returning.c_customer_sk
LEFT JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE d.d_year = 2002
  AND w.w_warehouse_sq_ft > 600000
  AND r.r_reason_desc LIKE '%color%'
  AND p.p_promo_name = 'Holiday Discount'
  AND cu_refunded.c_preferred_cust_flag = 'Y'
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    rr.total_return_amount,
    rr.return_cnt,
    r.r_reason_desc,
    d.d_year,
    p.p_promo_name
ORDER BY rr.total_return_amount DESC
LIMIT 100
