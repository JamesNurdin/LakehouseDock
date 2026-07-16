WITH returns_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_quarter_name,
        d_ret.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ws_open.web_name AS website_name,
        ws_open.web_state AS website_state,
        wp.wp_type,
        wp.wp_url,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        MAX(wr.wr_return_tax) AS max_return_tax,
        MIN(wr.wr_return_quantity) AS min_return_quantity,
        d_ret.d_date AS return_date,
        d_creation.d_current_month AS page_creation_month,
        d_access.d_current_month AS page_access_month
    FROM date_dim d_ret
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws_open
        ON ws_open.web_open_date_sk = d_ret.d_date_sk
    LEFT JOIN web_site ws_close
        ON ws_close.web_close_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2020
      AND wp.wp_type = 'article'
    GROUP BY
        d_ret.d_year,
        d_ret.d_quarter_name,
        d_ret.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ws_open.web_name,
        ws_open.web_state,
        wp.wp_type,
        wp.wp_url,
        d_ret.d_date,
        d_creation.d_current_month,
        d_access.d_current_month
)
SELECT
    r.d_year,
    r.d_quarter_name,
    r.s_store_name,
    r.s_city,
    r.s_state,
    r.website_name,
    r.website_state,
    r.wp_type,
    r.wp_url,
    r.total_returns,
    r.total_return_amount,
    r.total_net_loss,
    r.avg_return_amount,
    r.max_return_tax,
    r.min_return_quantity,
    r.page_creation_month,
    r.page_access_month,
    ROW_NUMBER() OVER (PARTITION BY r.s_store_name ORDER BY r.total_return_amount DESC) AS store_return_rank,
    ROW_NUMBER() OVER (PARTITION BY r.website_name ORDER BY r.total_returns DESC) AS website_return_rank
FROM returns_agg r
ORDER BY r.total_return_amount DESC
LIMIT 100
