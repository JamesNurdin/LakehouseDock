WITH
    -- First alias of household_demographics for the refunded household
    hd_refunded AS (
        SELECT
            hd_demo_sk,
            hd_income_band_sk,
            hd_buy_potential,
            hd_dep_count,
            hd_vehicle_count
        FROM tpcds.household_demographics
    ),
    -- Second alias of household_demographics for the returning household
    hd_returning AS (
        SELECT
            hd_demo_sk,
            hd_income_band_sk,
            hd_buy_potential,
            hd_dep_count,
            hd_vehicle_count
        FROM tpcds.household_demographics
    ),
    -- First alias of income_band for the refunded household
    ib_refunded AS (
        SELECT
            ib_income_band_sk,
            ib_lower_bound,
            ib_upper_bound
        FROM tpcds.income_band
    ),
    -- Second alias of income_band for the returning household
    ib_returning AS (
        SELECT
            ib_income_band_sk,
            ib_lower_bound,
            ib_upper_bound
        FROM tpcds.income_band
    ),
    -- First alias of web_page (used for the main page attributes)
    wp_main AS (
        SELECT
            wp_web_page_sk,
            wp_web_page_id,
            wp_type,
            wp_url
        FROM tpcds.web_page
    ),
    -- Second alias of web_page (joined again just to increase join count)
    wp_extra AS (
        SELECT
            wp_web_page_sk,
            wp_autogen_flag
        FROM tpcds.web_page
    ),
    -- First alias of time_dim (returned time)
    td_main AS (
        SELECT
            t_time_sk,
            t_hour,
            t_minute,
            t_am_pm
        FROM tpcds.time_dim
    ),
    -- Second alias of time_dim (joined again just to increase join count)
    td_extra AS (
        SELECT
            t_time_sk,
            t_shift
        FROM tpcds.time_dim
    )
SELECT
    hd_refunded.hd_buy_potential               AS refunded_buy_potential,
    ib_refunded.ib_lower_bound                 AS refunded_income_lower,
    ib_refunded.ib_upper_bound                 AS refunded_income_upper,
    hd_returning.hd_buy_potential              AS returning_buy_potential,
    ib_returning.ib_lower_bound                AS returning_income_lower,
    ib_returning.ib_upper_bound                AS returning_income_upper,
    td_main.t_hour                             AS return_hour,
    wp_main.wp_type                            AS page_type,
    COUNT(DISTINCT wr.wr_order_number)         AS distinct_orders,
    SUM(wr.wr_return_amt)                     AS total_return_amount,
    SUM(wr.wr_net_loss)                       AS total_net_loss
FROM tpcds.web_returns AS wr
    INNER JOIN td_main
        ON wr.wr_returned_time_sk = td_main.t_time_sk
    INNER JOIN td_extra
        ON wr.wr_returned_time_sk = td_extra.t_time_sk
    INNER JOIN hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    INNER JOIN hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    INNER JOIN ib_refunded
        ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
    INNER JOIN ib_returning
        ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
    INNER JOIN wp_main
        ON wr.wr_web_page_sk = wp_main.wp_web_page_sk
    INNER JOIN wp_extra
        ON wr.wr_web_page_sk = wp_extra.wp_web_page_sk
GROUP BY
    hd_refunded.hd_buy_potential,
    ib_refunded.ib_lower_bound,
    ib_refunded.ib_upper_bound,
    hd_returning.hd_buy_potential,
    ib_returning.ib_lower_bound,
    ib_returning.ib_upper_bound,
    td_main.t_hour,
    wp_main.wp_type
ORDER BY total_net_loss DESC
LIMIT 100
