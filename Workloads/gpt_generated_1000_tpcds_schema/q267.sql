WITH cr_agg AS (
    SELECT
        cr.cr_catalog_page_sk,
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        SUM(cr.cr_return_amount) AS sum_cr_return_amount,
        COUNT(*) AS cnt_cr
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100.00
    GROUP BY cr.cr_catalog_page_sk, cr.cr_returned_date_sk, cr.cr_refunded_customer_sk
),
wr_agg AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS sum_wr_return_amt,
        COUNT(*) AS cnt_wr
    FROM web_returns wr
    WHERE wr.wr_return_tax < 20.00
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_returned_date_sk
)
SELECT
    s.s_store_id,
    d_year.d_year,
    cp.cp_department,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(cr_agg.sum_cr_return_amount) AS total_catalog_return_amount,
    SUM(wr_agg.sum_wr_return_amt) AS total_web_return_amount,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d_year.d_date_sk
    ) AS catalog_returns_on_same_day,
    ROW_NUMBER() OVER (ORDER BY SUM(cr_agg.sum_cr_return_amount) DESC) AS rn
FROM cr_agg
INNER JOIN catalog_page cp
        ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN date_dim d_year
        ON cr_agg.cr_returned_date_sk = d_year.d_date_sk
INNER JOIN customer c
        ON cr_agg.cr_refunded_customer_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
INNER JOIN store s
        ON s.s_closed_date_sk = d_year.d_date_sk
INNER JOIN wr_agg
        ON wr_agg.wr_refunded_customer_sk = c.c_customer_sk
INNER JOIN date_dim d_wr
        ON wr_agg.wr_returned_date_sk = d_wr.d_date_sk
WHERE cp.cp_catalog_number = 5
  AND cd.cd_marital_status = 'M'
  AND d_year.d_dom = 12
GROUP BY s.s_store_id, d_year.d_year, cp.cp_department, d_year.d_date_sk
ORDER BY total_catalog_return_amount DESC
LIMIT 100
