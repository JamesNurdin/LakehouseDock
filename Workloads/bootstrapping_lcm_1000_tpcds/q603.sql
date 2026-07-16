SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ret.d_year AS return_year,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_credit_rating AS refunded_credit_rating,
    cd_ret.cd_marital_status AS returning_marital_status,
    cd_ret.cd_dep_count AS returning_dep_count,
    wp.wp_type,
    wp.wp_url,
    d_page_creation.d_month_seq AS page_creation_month_seq,
    d_page_creation.d_day_name AS page_creation_day_name,
    d_page_access.d_month_seq AS page_access_month_seq,
    d_page_access.d_day_name AS page_access_day_name,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_fee) AS avg_fee,
    MAX(wr.wr_return_tax) AS max_return_tax,
    MIN(wr.wr_return_quantity) AS min_return_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE d_ret.d_year BETWEEN 2010 AND 2020
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    cd_ref.cd_gender,
    cd_ref.cd_credit_rating,
    cd_ret.cd_marital_status,
    cd_ret.cd_dep_count,
    wp.wp_type,
    wp.wp_url,
    d_page_creation.d_month_seq,
    d_page_creation.d_day_name,
    d_page_access.d_month_seq,
    d_page_access.d_day_name
ORDER BY total_return_amount DESC
LIMIT 100
