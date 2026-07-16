WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    GROUP BY
        sr.sr_store_sk,
        sr.sr_returned_date_sk
),
aggregated AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        d_cc_closed.d_date AS call_center_closed_date,
        d_cc_open.d_date AS call_center_open_date,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        sr_agg.total_returns,
        sr_agg.total_net_loss,
        AVG(wp_creation.wp_image_count) AS avg_image_count_on_cc_open,
        COUNT(DISTINCT wp_access.wp_web_page_sk) AS distinct_pages_accessed_on_return_date,
        s.s_floor_space AS store_floor_space,
        DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_open_to_close_days
    FROM call_center cc
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN sr_agg
        ON sr_agg.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN web_page wp_creation
        ON wp_creation.wp_creation_date_sk = d_cc_open.d_date_sk
    LEFT JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        d_cc_closed.d_date,
        d_cc_open.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        sr_agg.total_returns,
        sr_agg.total_net_loss,
        s.s_floor_space,
        DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date)
)
SELECT
    call_center_name,
    call_center_city,
    store_name,
    store_city,
    call_center_closed_date,
    call_center_open_date,
    return_year,
    return_month,
    total_returns,
    total_net_loss,
    avg_image_count_on_cc_open,
    distinct_pages_accessed_on_return_date,
    store_floor_space,
    call_center_open_to_close_days,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
