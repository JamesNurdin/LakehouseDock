WITH agg_returns AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_state AS s_state,
        s.s_manager AS s_manager,
        d_return.d_year AS d_year,
        d_return.d_month_seq AS d_month_seq,
        d_return.d_current_month AS d_current_month,
        hd_returning.hd_buy_potential AS hd_buy_potential,
        hd_refunded.hd_income_band_sk AS hd_income_band_sk,
        wp.wp_type AS wp_type,
        wp.wp_url AS wp_url,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        MAX(wr.wr_return_tax) AS max_return_tax,
        MIN(d_creation.d_date) AS earliest_creation_date,
        MAX(d_access.d_date) AS latest_access_date
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    WHERE d_return.d_year >= 2020
      AND s.s_state IN ('CA', 'NY', 'TX')
    GROUP BY
        s.s_store_id,
        s.s_state,
        s.s_manager,
        d_return.d_year,
        d_return.d_month_seq,
        d_return.d_current_month,
        hd_returning.hd_buy_potential,
        hd_refunded.hd_income_band_sk,
        wp.wp_type,
        wp.wp_url
)
SELECT
    s_store_id,
    s_state,
    s_manager,
    d_year,
    d_month_seq,
    d_current_month,
    hd_buy_potential,
    hd_income_band_sk,
    wp_type,
    wp_url,
    total_returns,
    total_return_amount,
    total_fee,
    total_net_loss,
    avg_return_qty,
    max_return_tax,
    earliest_creation_date,
    latest_access_date,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS store_return_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100
