WITH cr_agg AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_returned_date_sk,
        cr_refunded_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 0
      AND cr_return_quantity > 0
      AND cr_returned_date_sk IS NOT NULL
    GROUP BY cr_call_center_sk, cr_ship_mode_sk, cr_returned_date_sk, cr_refunded_customer_sk
)
SELECT
    cc.cc_name,
    sm.sm_code,
    d.d_year,
    CASE
        WHEN cc.cc_class = 'large' THEN 'LARGE'
        WHEN cc.cc_class = 'medium' THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS center_type,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(cr_agg.total_return_amount) AS sum_return_amount,
    SUM(cr_agg.total_return_qty) AS sum_return_qty,
    AVG(cr_agg.total_return_amount) AS avg_return_amount_per_center_ship,
    MAX(c.c_birth_month) AS max_birth_month
FROM cr_agg
JOIN call_center cc ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d ON cr_agg.cr_returned_date_sk = d.d_date_sk
JOIN customer c ON cr_agg.cr_refunded_customer_sk = c.c_customer_sk
WHERE cc.cc_class IN ('large', 'medium')
  AND cc.cc_mkt_class LIKE '%National%'
  AND sm.sm_code IN ('AIR', 'SEA')
  AND sm.sm_contract NOT LIKE 'Ek%'
  AND d.d_year BETWEEN 2000 AND 2005
  AND c.c_birth_month IN (2, 9, 12)
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
          AND cr2.cr_return_amount > 5000
        LIMIT 1
      )
GROUP BY cc.cc_name, sm.sm_code, d.d_year, cc.cc_class
HAVING SUM(cr_agg.total_return_amount) > 10000
ORDER BY sum_return_amount DESC
LIMIT 100
