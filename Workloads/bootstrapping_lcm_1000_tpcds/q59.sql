SELECT
    s.s_state,
    d_return.d_year AS return_year,
    d_store_closed.d_year AS store_closed_year,
    CASE
        WHEN cd.cd_credit_rating = 'A' THEN 'Excellent'
        WHEN cd.cd_credit_rating = 'B' THEN 'Good'
        ELSE 'Other'
    END AS credit_rating_group,
    wp.wp_type,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee ELSE 0 END) AS total_fees,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date
FROM store_returns sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_return.d_date_sk
    AND wp.wp_access_date_sk = d_return.d_date_sk
GROUP BY
    s.s_state,
    d_return.d_year,
    d_store_closed.d_year,
    CASE
        WHEN cd.cd_credit_rating = 'A' THEN 'Excellent'
        WHEN cd.cd_credit_rating = 'B' THEN 'Good'
        ELSE 'Other'
    END,
    wp.wp_type
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
