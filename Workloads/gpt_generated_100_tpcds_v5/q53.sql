WITH catalog_agg AS (
    SELECT
        cr_warehouse_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_tax > 10
      AND cr_reversed_charge < 500
      AND cr_return_quantity > 0
    GROUP BY cr_warehouse_sk, cr_returned_date_sk
),
distinct_store AS (
    SELECT DISTINCT
        sr_customer_sk,
        sr_returned_date_sk,
        sr_return_time_sk
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 50
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    COUNT(DISTINCT ds.sr_customer_sk) AS distinct_customers,
    SUM(ca.total_return_amount) AS sum_return_amount,
    AVG(ca.total_return_amount) AS avg_return_per_warehouse
FROM catalog_agg ca
JOIN warehouse w
    ON ca.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d
    ON ca.cr_returned_date_sk = d.d_date_sk
JOIN distinct_store ds
    ON ds.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON ds.sr_return_time_sk = t.t_time_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE w.w_city IN ('Riverside', 'Fairview')
  AND t.t_hour BETWEEN 8 AND 20
  AND t.t_am_pm = 'PM'
  AND ws.web_tax_percentage > 5
GROUP BY d.d_year, w.w_warehouse_name
HAVING SUM(ca.total_return_amount) > 1000
ORDER BY sum_return_amount DESC
LIMIT 100
