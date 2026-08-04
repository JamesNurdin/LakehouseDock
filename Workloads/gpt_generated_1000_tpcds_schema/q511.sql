WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    dr.d_year,
    w.w_warehouse_name,
    cd.cd_gender,
    SUM(sr.cr_return_amount) AS total_return_amount,
    AVG(sr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT sr.cr_order_number) AS distinct_orders,
    MAX(sr.cr_return_amount) AS max_return_amount,
    CASE
        WHEN SUM(sr.cr_return_amount) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS return_volume_category,
    (
        SELECT COUNT(*)
        FROM promotion p_sub
        WHERE p_sub.p_start_date_sk = dr.d_date_sk
    ) AS promos_starting_on_return_date
FROM sampled_returns sr
JOIN date_dim dr
    ON sr.cr_returned_date_sk = dr.d_date_sk
JOIN warehouse w
    ON sr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON sr.cr_returning_cdemo_sk = cd.cd_demo_sk
FULL OUTER JOIN promotion p
    ON p.p_start_date_sk = dr.d_date_sk
WHERE dr.d_year = 2002
  AND w.w_state = 'CA'
  AND cd.cd_education_status = '4 yr Degree         '
GROUP BY dr.d_year, w.w_warehouse_name, cd.cd_gender, dr.d_date_sk
ORDER BY total_return_amount DESC
LIMIT 100
