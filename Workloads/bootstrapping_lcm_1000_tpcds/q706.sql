SELECT
    d.d_year AS return_year,
    d.d_quarter_name AS quarter,
    CASE WHEN cd_ref.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category,
    cd_ref.cd_marital_status,
    cd_ret.cd_education_status,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_tax,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    MAX(p.p_cost) AS max_promo_cost,
    COUNT(DISTINCT s.s_store_id) AS distinct_store_cnt,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promo_cnt
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
    AND p.p_end_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    CASE WHEN cd_ref.cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
    cd_ref.cd_marital_status,
    cd_ret.cd_education_status,
    s.s_state
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
