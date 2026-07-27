WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_store_credit > 50
      AND cr_return_amount BETWEEN 10 AND 500
      AND cr_return_quantity >= 1
)
SELECT
    r.r_reason_desc,
    t.t_hour,
    hd_refunded.hd_vehicle_count AS refunded_vehicle_count,
    hd_returning.hd_vehicle_count AS returning_vehicle_count,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(fr.cr_return_quantity) AS min_qty,
    MAX(fr.cr_return_quantity) AS max_qty
FROM filtered_returns fr
JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t ON fr.cr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_refunded
    ON fr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON fr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
WHERE r.r_reason_id IN ('AAAAAAAAEBAAAAAA','AAAAAAAACBAAAAAA','AAAAAAAAGAAAAAAA')
  AND hd_refunded.hd_vehicle_count IN (1,2,3)
  AND hd_returning.hd_vehicle_count <> -1
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    r.r_reason_desc,
    t.t_hour,
    hd_refunded.hd_vehicle_count,
    hd_returning.hd_vehicle_count
ORDER BY total_return_amount DESC
LIMIT 100
