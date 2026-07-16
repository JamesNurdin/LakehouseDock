WITH detailed AS (
    SELECT
        dr_ret.d_year AS return_year,
        dr_ret.d_month_seq AS return_month_seq,
        dr_ret.d_quarter_name AS return_quarter,
        r.r_reason_id,
        r.r_reason_desc,
        s.s_market_desc,
        s.s_city,
        s.s_state,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wp.wp_image_count,
        wp.wp_url,
        DATE_DIFF('day', d_cre.d_date, dr_ret.d_date) AS days_creation_to_return,
        DATE_DIFF('day', dr_ret.d_date, d_acc.d_date) AS days_return_to_access
    FROM web_returns wr
    JOIN date_dim dr_ret
        ON wr.wr_returned_date_sk = dr_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = dr_ret.d_date_sk
    JOIN date_dim d_cre
        ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc
        ON wp.wp_access_date_sk = d_acc.d_date_sk
)
SELECT
    agg.return_year,
    agg.return_month_seq,
    agg.return_quarter,
    agg.r_reason_id,
    agg.r_reason_desc,
    agg.s_market_desc,
    agg.s_city,
    agg.s_state,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.avg_return_quantity,
    agg.avg_days_creation_to_return,
    agg.avg_days_return_to_access,
    agg.max_image_count,
    agg.sample_url,
    RANK() OVER (PARTITION BY agg.s_market_desc ORDER BY agg.total_return_amount DESC) AS market_return_rank
FROM (
    SELECT
        return_year,
        return_month_seq,
        return_quarter,
        r_reason_id,
        r_reason_desc,
        s_market_desc,
        s_city,
        s_state,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_quantity) AS avg_return_quantity,
        AVG(days_creation_to_return) AS avg_days_creation_to_return,
        AVG(days_return_to_access) AS avg_days_return_to_access,
        MAX(wp_image_count) AS max_image_count,
        ANY_VALUE(wp_url) AS sample_url
    FROM detailed
    GROUP BY
        return_year,
        return_month_seq,
        return_quarter,
        r_reason_id,
        r_reason_desc,
        s_market_desc,
        s_city,
        s_state
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
