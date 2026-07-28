WITH warehouse_reason_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        r.r_reason_desc,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 20
      AND cr.cr_return_quantity >= 1
      AND r.r_reason_desc LIKE '%missing%'
      AND w.w_state IN ('CA', 'TX', 'NY')
      AND cr.cr_reversed_charge < 500
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_state, r.r_reason_desc
    HAVING COUNT(*) > 2
)
SELECT DISTINCT
    cr.cr_order_number,
    wra.w_warehouse_id,
    wra.w_state,
    wra.r_reason_desc,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    wra.return_cnt,
    wra.total_return_amount,
    wra.avg_quantity,
    RANK() OVER (PARTITION BY wra.r_reason_desc ORDER BY wra.total_return_amount DESC) AS reason_warehouse_rank,
    CASE
        WHEN wra.total_return_amount = (SELECT MAX(total_return_amount) FROM warehouse_reason_agg) THEN 'TOP_WAREHOUSE'
        ELSE 'OTHER'
    END AS top_flag
FROM catalog_returns cr
JOIN warehouse_reason_agg wra ON cr.cr_warehouse_sk = wra.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_city LIKE 'Williams%'
  AND cd.cd_gender = 'M'
  AND cr.cr_return_amount > 30
  AND cr.cr_reversed_charge < 100
ORDER BY wra.r_reason_desc, reason_warehouse_rank, wra.total_return_amount DESC
LIMIT 100
