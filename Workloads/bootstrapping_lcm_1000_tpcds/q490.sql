SELECT
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
    cd.cd_education_status,
    s.s_state,
    dr.d_year,
    dr.d_quarter_seq,
    FLOOR(sr.sr_return_amt / 100) * 100 AS return_amount_bracket,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(sr.sr_store_credit) AS total_store_credit,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created
FROM store_returns sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dr.d_date_sk
WHERE ds.d_year >= 2020
GROUP BY
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
    cd.cd_education_status,
    s.s_state,
    dr.d_year,
    dr.d_quarter_seq,
    FLOOR(sr.sr_return_amt / 100) * 100
HAVING COUNT(*) > 10
ORDER BY total_return_amt DESC
LIMIT 200
