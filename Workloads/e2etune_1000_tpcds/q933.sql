WITH warehouse_income AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_sk,
        w.w_country,
        w.w_state,
        w.w_warehouse_sq_ft,
        w.w_gmt_offset,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM warehouse w
    JOIN income_band ib
      ON w.w_warehouse_sq_ft BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE w.w_state IN ('CA', 'NY', 'TX')
),
reason_counts AS (
    SELECT
        wi.w_warehouse_id,
        COUNT(r.r_reason_id) AS reason_cnt,
        MIN(r.r_reason_desc) AS sample_reason
    FROM warehouse_income wi
    LEFT JOIN reason r
      ON wi.w_warehouse_sk % 5 = r.r_reason_sk % 5
    GROUP BY wi.w_warehouse_id
)
SELECT
    wi.w_country,
    wi.ib_income_band_sk,
    COUNT(*) AS warehouse_cnt,
    AVG(wi.w_warehouse_sq_ft) AS avg_sq_ft,
    SUM(wi.w_gmt_offset) AS total_gmt_offset,
    SUM(rc.reason_cnt) AS total_reason_cnt,
    MIN(rc.sample_reason) AS any_reason_desc
FROM warehouse_income wi
JOIN reason_counts rc
  ON wi.w_warehouse_id = rc.w_warehouse_id
GROUP BY wi.w_country, wi.ib_income_band_sk
HAVING COUNT(*) >= 5
ORDER BY total_reason_cnt DESC, avg_sq_ft DESC
LIMIT 100
