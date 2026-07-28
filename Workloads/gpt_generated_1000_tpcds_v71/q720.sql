WITH recent_large_returns AS (
    SELECT cr.*
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200.00
      AND cr.cr_return_quantity >= 2
      AND cr.cr_returned_date_sk >= 2451500
),
union_returns AS (
    SELECT 
        cr_returned_date_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_order_number,
        cr_reason_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_refunded_customer_sk,
        cr_returning_customer_sk
    FROM recent_large_returns
    UNION ALL
    SELECT 
        cr_returned_date_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_order_number,
        cr_reason_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        cr_catalog_page_sk,
        cr_refunded_customer_sk,
        cr_returning_customer_sk
    FROM catalog_returns
    WHERE cr_returned_date_sk < 2451500
      AND cr_return_amount < 300.00
)
SELECT
    r.r_reason_desc,
    w.w_state,
    cc.cc_name,
    COUNT(DISTINCT ur.cr_order_number) AS distinct_orders,
    SUM(ur.cr_return_amount) AS total_return_amount,
    AVG(ur.cr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN ur.cr_return_amount > 500 THEN 1 ELSE 0 END) AS high_value_returns,
    (SELECT COUNT(*) FROM customer c2 WHERE c2.c_birth_year = 1965) AS customers_born_1965
FROM union_returns ur
JOIN reason r ON ur.cr_reason_sk = r.r_reason_sk
JOIN warehouse w ON ur.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON ur.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON ur.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON ur.cr_refunded_customer_sk = c.c_customer_sk
WHERE r.r_reason_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAALAAAAAAA')
  AND c.c_birth_month = 7
  AND w.w_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_number >= 10
          AND cp2.cp_catalog_page_sk = ur.cr_catalog_page_sk
    )
GROUP BY ROLLUP (r.r_reason_desc, w.w_state, cc.cc_name)
ORDER BY total_return_amount DESC
LIMIT 100
