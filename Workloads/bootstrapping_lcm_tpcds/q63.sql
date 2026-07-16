WITH aggregated AS (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_store_sk,
        d_return.d_year,
        d_return.d_month_seq,
        d_return.d_current_month,
        r.r_reason_desc,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        MIN(d_page_creation.d_date) AS earliest_page_creation_date,
        MAX(d_page_access.d_date) AS latest_page_access_date
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_page_creation
        ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    WHERE d_return.d_year >= 2020
    GROUP BY
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_store_sk,
        d_return.d_year,
        d_return.d_month_seq,
        d_return.d_current_month,
        r.r_reason_desc
)
SELECT
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.s_country,
    a.d_year,
    a.d_month_seq,
    a.d_current_month,
    a.r_reason_desc,
    a.distinct_pages,
    a.total_return_amount,
    a.total_return_quantity,
    a.total_fee,
    a.total_net_loss,
    a.return_count,
    a.earliest_page_creation_date,
    a.latest_page_access_date,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_sk, a.d_year, a.d_month_seq ORDER BY a.total_return_amount DESC) AS reason_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
