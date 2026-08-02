WITH cr_agg AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_reason_sk,
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 10
      AND cr.cr_return_amount > 0
      AND cr.cr_return_tax > 0
      AND cr.cr_fee >= 0
      AND cr.cr_return_ship_cost >= 0
    GROUP BY cr.cr_call_center_sk, cr.cr_reason_sk, cr.cr_returning_customer_sk
)
SELECT DISTINCT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    r.r_reason_desc,
    c.c_customer_id,
    cd.cd_gender,
    ca.ca_city AS customer_city,
    cragg.total_return_qty,
    cragg.total_return_amount,
    cragg.return_cnt,
    cragg.avg_return_amount,
    (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
    ) AS max_return_amount_for_center,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr3
        WHERE cr3.cr_call_center_sk = cc.cc_call_center_sk
          AND cr3.cr_return_quantity > 30
    ) AS high_qty_return_cnt
FROM cr_agg cragg
JOIN call_center cc
    ON cragg.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cragg.cr_reason_sk = r.r_reason_sk
JOIN customer c
    ON cragg.cr_returning_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_sq_ft > 500000000
  AND cc.cc_state = 'CA'
  AND cc.cc_rec_end_date = DATE '2000-12-31'
  AND r.r_reason_desc LIKE '%Damaged%'
  AND cd.cd_gender = 'M'
  AND ca.ca_city = 'Pine Oak'
ORDER BY cragg.total_return_amount DESC
OFFSET 0
LIMIT 100
