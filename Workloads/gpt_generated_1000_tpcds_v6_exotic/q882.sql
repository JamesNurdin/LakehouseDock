WITH d2000 AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2000
),
ca AS (
    SELECT DISTINCT s_city
    FROM store
    WHERE s_state = 'CA'
)
SELECT
    cc.cc_call_center_id,
    'sales' AS activity_type,
    SUM(cs.cs_net_paid) AS total_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    (
        SELECT AVG(cc2.cc_gmt_offset)
        FROM call_center cc2
        WHERE cc2.cc_state = cc.cc_state
    ) AS avg_state_gmt_offset
FROM catalog_sales cs
JOIN d2000 d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_city IN (SELECT s_city FROM ca)
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
          AND cp.cp_type = 'Catalog'
    )
GROUP BY cc.cc_call_center_id, cc.cc_state
UNION ALL
SELECT
    cc.cc_call_center_id,
    'returns' AS activity_type,
    SUM(cr.cr_net_loss) AS total_amount,
    COUNT(DISTINCT cr.cr_order_number) AS order_count,
    (
        SELECT AVG(cc2.cc_gmt_offset)
        FROM call_center cc2
        WHERE cc2.cc_state = cc.cc_state
    ) AS avg_state_gmt_offset
FROM catalog_returns cr
JOIN d2000 d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cc.cc_city IN (SELECT s_city FROM ca)
  AND r.r_reason_desc = 'Damaged'
GROUP BY cc.cc_call_center_id, cc.cc_state
ORDER BY total_amount DESC
LIMIT 100
