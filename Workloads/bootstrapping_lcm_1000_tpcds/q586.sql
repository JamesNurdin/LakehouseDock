SELECT
    s.s_store_id,
    s.s_state,
    s.s_floor_space,
    cd_ref.cd_gender,
    cd_ref.cd_education_status,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_creation.d_month_seq AS page_creation_month_seq,
    d_access.d_day_name AS page_access_day,
    COUNT(DISTINCT wr.wr_order_number) AS total_orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_return_quantity) AS total_return_quantity
FROM web_returns wr
INNER JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
INNER JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
INNER JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
INNER JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
INNER JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE cd_ref.cd_credit_rating = 'AA'
  AND wp.wp_type = 'Content'
  AND s.s_market_id IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_state,
    s.s_floor_space,
    cd_ref.cd_gender,
    cd_ref.cd_education_status,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_creation.d_month_seq,
    d_access.d_day_name
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
