WITH returns_joined AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_web_page_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        t.t_hour,
        t.t_am_pm,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        wp.wp_type,
        wp.wp_url
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
),
agg_returns AS (
    SELECT
        t_hour,
        t_am_pm,
        wp_type,
        returning_buy_potential,
        SUM(wr_return_quantity) AS total_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM returns_joined
    GROUP BY t_hour, t_am_pm, wp_type, returning_buy_potential
)
SELECT
    t_hour,
    t_am_pm,
    wp_type,
    returning_buy_potential,
    total_quantity,
    total_return_amount,
    total_net_loss,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS rank_by_net_loss
FROM agg_returns
ORDER BY t_hour, rank_by_net_loss
LIMIT 200
