WITH sr_sample AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
),
inner_joined AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        rd.d_year,
        rt.t_hour,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r1.r_reason_desc,
        fd.d_year AS ship_year,
        r2.r_reason_desc AS secondary_reason_desc,
        t2.t_shift AS secondary_shift
    FROM sr_sample sr
    INNER JOIN date_dim rd
        ON sr.sr_returned_date_sk = rd.d_date_sk               -- join 1
    INNER JOIN time_dim rt
        ON sr.sr_return_time_sk = rt.t_time_sk                 -- join 2
    INNER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk                 -- join 3
    INNER JOIN reason r1
        ON sr.sr_reason_sk = r1.r_reason_sk                    -- join 4
    INNER JOIN date_dim fd
        ON c.c_first_shipto_date_sk = fd.d_date_sk             -- join 5
    INNER JOIN date_dim fs
        ON c.c_first_sales_date_sk = fs.d_date_sk              -- join 6
    INNER JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk                    -- join 7
    INNER JOIN time_dim t2
        ON sr.sr_return_time_sk = t2.t_time_sk                 -- join 8
    WHERE sr.sr_return_amt_inc_tax > (
        SELECT AVG(sr_return_amt_inc_tax) FROM store_returns
    )
)
SELECT
    COALESCE(CAST(ij.d_year AS VARCHAR), r_full.r_reason_desc) AS year_or_reason,
    ij.r_reason_desc,
    COUNT(*) AS returns_cnt,
    SUM(ij.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(ij.sr_return_amt_inc_tax) AS avg_return_inc_tax,
    CASE
        WHEN SUM(ij.sr_return_amt_inc_tax) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS return_volume_flag
FROM inner_joined ij
FULL OUTER JOIN reason r_full
    ON ij.sr_reason_sk = r_full.r_reason_sk                 -- join 9 (full outer)
GROUP BY
    COALESCE(CAST(ij.d_year AS VARCHAR), r_full.r_reason_desc),
    ij.r_reason_desc
ORDER BY returns_cnt DESC
LIMIT 100
