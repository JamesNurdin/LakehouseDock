WITH sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_customer_sk,
        sr_hdemo_sk,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(sr_return_amt_inc_tax) AS avg_return_inc_tax,
        MAX(sr_return_amt_inc_tax) AS max_return_inc_tax
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 1000
    GROUP BY sr_returned_date_sk, sr_customer_sk, sr_hdemo_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_income_band_sk,
    cp.cp_catalog_page_id,
    d_ret.d_year,
    SUM(sr_agg.total_return_inc_tax) AS sum_total_return_inc_tax,
    SUM(sr_agg.return_cnt) AS total_returns,
    AVG(sr_agg.avg_return_inc_tax) AS avg_return_per_return,
    MAX(sr_agg.max_return_inc_tax) AS max_return_amount
FROM sr_agg
JOIN date_dim d_ret ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer c ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
WHERE
    c.c_birth_country = 'JAPAN'
    AND hd.hd_income_band_sk = 14
    AND d_ret.d_year = 2001
    AND cp.cp_department = 'Electronics'
    AND d_ret.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_income_band_sk,
    cp.cp_catalog_page_id,
    d_ret.d_year
HAVING
    SUM(sr_agg.total_return_inc_tax) > (SELECT AVG(sr_return_amt_inc_tax) FROM store_returns) * 2
ORDER BY
    sum_total_return_inc_tax DESC
LIMIT 100
