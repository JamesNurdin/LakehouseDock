WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        cp.cp_type,
        r.r_reason_sk,
        r.r_reason_desc,
        r.r_reason_id,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        cr.cr_order_number,
        cust.c_customer_sk,
        cust.c_salutation,
        cust.c_first_name,
        cust.c_last_name
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_gmt_offset = -8.00
      AND cp.cp_type = 'Catalog'
      AND cp.cp_catalog_number BETWEEN 10 AND 20
      AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
      AND cr.cr_return_amount > 50.00
      AND cr.cr_return_ship_cost < 2000.00
)
SELECT
    base.cc_name,
    base.cp_catalog_number,
    base.r_reason_desc,
    cat.category,
    SUM(base.cr_return_amount) AS total_return_amount,
    AVG(base.cr_fee) AS avg_fee,
    COUNT(DISTINCT base.c_customer_sk) AS unique_customers,
    MIN(base.cr_net_loss) AS min_net_loss,
    MAX(base.cr_net_loss) AS max_net_loss,
    lateral_counts.related_return_count
FROM base
CROSS JOIN (SELECT 1 AS category UNION ALL SELECT 2 AS category) AS cat
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS related_return_count
    FROM catalog_returns cr2
    WHERE cr2.cr_call_center_sk = base.cc_call_center_sk
      AND cr2.cr_return_quantity > base.cr_return_quantity
) AS lateral_counts ON TRUE
GROUP BY
    base.cc_name,
    base.cp_catalog_number,
    base.r_reason_desc,
    cat.category,
    lateral_counts.related_return_count
ORDER BY total_return_amount DESC
OFFSET 20
LIMIT 100
