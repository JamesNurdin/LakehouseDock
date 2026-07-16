SELECT
    s.s_store_id,
    s.s_store_name,
    ds.d_year AS store_closed_year,
    dr.d_year AS return_year,
    dr.d_quarter_name AS return_quarter,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT wpc.wp_web_page_id) AS pages_created_on_store_close,
    COUNT(DISTINCT wpa.wp_web_page_id) AS pages_accessed_on_return_date
FROM store_returns sr
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
LEFT JOIN web_page wpc
    ON wpc.wp_creation_date_sk = ds.d_date_sk
LEFT JOIN web_page wpa
    ON wpa.wp_access_date_sk = dr.d_date_sk
WHERE dr.d_year >= 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ds.d_year,
    dr.d_year,
    dr.d_quarter_name,
    cd.cd_gender,
    cd.cd_marital_status
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 50
