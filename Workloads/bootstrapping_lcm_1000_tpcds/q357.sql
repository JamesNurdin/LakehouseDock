SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')) AS return_month,
    CASE
        WHEN cr.cr_return_amount < 100 THEN 'Small'
        WHEN cr.cr_return_amount < 500 THEN 'Medium'
        ELSE 'Large'
    END AS return_size_bucket,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT rc.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT rrc.c_customer_sk) AS distinct_returning_customers,
    AVG(date_diff('day', d_shipto.d_date, d.d_date)) AS avg_days_since_first_shipto,
    AVG(date_diff('day', d_sales.d_date, d.d_date)) AS avg_days_since_first_sales,
    SUM(CASE WHEN d_sales.d_year = d.d_year AND d_sales.d_moy = d.d_moy THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_returns_in_first_sales_month
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer rc
    ON cr.cr_refunded_customer_sk = rc.c_customer_sk
JOIN customer rrc
    ON cr.cr_returning_customer_sk = rrc.c_customer_sk
LEFT JOIN date_dim d_shipto
    ON rc.c_first_shipto_date_sk = d_shipto.d_date_sk
LEFT JOIN date_dim d_sales
    ON rc.c_first_sales_date_sk = d_sales.d_date_sk
WHERE cr.cr_return_amount IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    CONCAT(CAST(d.d_year AS VARCHAR), '-', LPAD(CAST(d.d_moy AS VARCHAR), 2, '0')),
    CASE
        WHEN cr.cr_return_amount < 100 THEN 'Small'
        WHEN cr.cr_return_amount < 500 THEN 'Medium'
        ELSE 'Large'
    END
ORDER BY total_returns DESC
LIMIT 100
