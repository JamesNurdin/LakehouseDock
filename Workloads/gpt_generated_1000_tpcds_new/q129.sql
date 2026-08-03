WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amt
    FROM catalog_returns
)
SELECT store_name,
       year,
       month_seq,
       total_return_amount,
       return_cnt
FROM (
    SELECT
        s.s_store_name AS store_name,
        dr.d_year AS year,
        dr.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2001
      AND cr.cr_store_credit > 100
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
    GROUP BY s.s_store_name, dr.d_year, dr.d_month_seq

    UNION ALL

    SELECT
        s.s_store_name AS store_name,
        dr.d_year AS year,
        dr.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2002
      AND cr.cr_return_quantity > 5
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
    GROUP BY s.s_store_name, dr.d_year, dr.d_month_seq
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
