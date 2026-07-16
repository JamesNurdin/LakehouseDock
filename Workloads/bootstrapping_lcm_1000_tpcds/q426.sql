SELECT
    cd.cd_credit_rating,
    cd.cd_gender,
    s.s_state,
    dr_ret.d_year,
    CASE
        WHEN dr_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN dr_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN dr_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    CASE
        WHEN sr.sr_return_amt > 500 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_return_amt * sr.sr_return_quantity) AS weighted_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_fee) AS avg_fee,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END) AS home_page_visits,
    MIN(dr_wp_access.d_date) AS earliest_access_date,
    MAX(dr_wp_access.d_date) AS latest_access_date
FROM store_returns sr
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr_ret
    ON sr.sr_returned_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_closed
    ON s.s_closed_date_sk = dr_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dr_ret.d_date_sk
JOIN date_dim dr_wp_access
    ON wp.wp_access_date_sk = dr_wp_access.d_date_sk
WHERE dr_ret.d_year = 2020
  AND s.s_state = 'CA'
  AND dr_wp_access.d_year = 2020
GROUP BY
    cd.cd_credit_rating,
    cd.cd_gender,
    s.s_state,
    dr_ret.d_year,
    CASE
        WHEN dr_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN dr_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN dr_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    CASE
        WHEN sr.sr_return_amt > 500 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_net_loss DESC
LIMIT 100
