SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wp.wp_type,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_income_band_sk,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    MAX(wr.wr_return_amt_inc_tax) AS max_return_amt_inc_tax,
    MIN(wr.wr_return_amt_inc_tax) AS min_return_amt_inc_tax,
    d_creation.d_year AS page_creation_year,
    d_access.d_week_seq AS page_access_week,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space BETWEEN 20000 AND 50000 THEN 'Medium Store'
        ELSE 'Small Store'
    END AS store_size_category
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
LEFT JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
  AND wp.wp_type IS NOT NULL
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wp.wp_type,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_income_band_sk,
    d_creation.d_year,
    d_access.d_week_seq,
    CASE
        WHEN s.s_floor_space > 50000 THEN 'Large Store'
        WHEN s.s_floor_space BETWEEN 20000 AND 50000 THEN 'Medium Store'
        ELSE 'Small Store'
    END
ORDER BY total_return_amount DESC
LIMIT 100
