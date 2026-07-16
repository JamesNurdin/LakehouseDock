WITH agg AS (
    SELECT
        d_ret.d_date AS return_date,
        d_ret.d_year AS d_year,
        d_ret.d_month_seq AS d_month_seq,
        r.r_reason_desc AS r_reason_desc,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        s.s_geography_class AS s_geography_class,
        wp.wp_type AS wp_type,
        wp.wp_url AS wp_url,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_fee), 0) AS return_to_fee_ratio
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year = 2022
      AND d_create.d_month_seq = d_ret.d_month_seq
      AND d_access.d_month_seq = d_ret.d_month_seq
    GROUP BY
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        r.r_reason_desc,
        s.s_store_name,
        s.s_state,
        s.s_geography_class,
        wp.wp_type,
        wp.wp_url
)
SELECT
    return_date,
    d_year,
    d_month_seq,
    r_reason_desc,
    s_store_name,
    s_state,
    s_geography_class,
    wp_type,
    wp_url,
    num_returns,
    total_return_amount,
    total_fee,
    total_net_loss,
    avg_return_amount,
    return_to_fee_ratio,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_return_amount DESC) AS store_return_rank,
    DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS overall_return_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
