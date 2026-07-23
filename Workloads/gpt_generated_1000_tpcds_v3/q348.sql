WITH base_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_web_page_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
)
SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    t_ret.t_hour,
    hd_returning.hd_buy_potential,
    hd_returning.hd_dep_count,
    wp.wp_type,
    promo_start.p_promo_name,
    promo_end.p_discount_active,
    SUM(br.wr_return_amt_inc_tax) AS total_return_amount,
    SUM(br.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM base_returns br
JOIN date_dim d_ret
    ON br.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON br.wr_returned_time_sk = t_ret.t_time_sk
JOIN household_demographics hd_refunded
    ON br.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON br.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN web_page wp
    ON br.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN promotion promo_start
    ON promo_start.p_start_date_sk = d_ret.d_date_sk
JOIN promotion promo_end
    ON promo_end.p_end_date_sk = d_ret.d_date_sk
WHERE d_ret.d_dow BETWEEN 1 AND 5
  AND EXISTS (
        SELECT 1
        FROM promotion p_active
        WHERE p_active.p_start_date_sk <= d_ret.d_date_sk
          AND p_active.p_end_date_sk >= d_ret.d_date_sk
          AND p_active.p_discount_active = 'Y'
          AND p_active.p_channel_catalog = 'N'
    )
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    t_ret.t_hour,
    hd_returning.hd_buy_potential,
    hd_returning.hd_dep_count,
    wp.wp_type,
    promo_start.p_promo_name,
    promo_end.p_discount_active
HAVING SUM(br.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
