WITH enriched AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        d.d_year AS return_year,
        d.d_month_seq AS month_seq,
        wp.wp_url AS page_url,
        wp.wp_type AS page_type,
        d_creation.d_year AS creation_year,
        d_access.d_year AS access_year,
        ws.web_name AS site_name,
        ws.web_market_manager AS market_manager,
        d_close.d_year AS close_year,
        d_ret2.d_date_sk AS dummy_ret2_date,
        wp2.wp_web_page_id AS dummy_wp2_id
    FROM date_dim d
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    -- additional alias joins to increase join count
    JOIN date_dim d_ret2
        ON wr.wr_returned_date_sk = d_ret2.d_date_sk
    JOIN web_page wp2
        ON wr.wr_web_page_sk = wp2.wp_web_page_sk
)
SELECT
    return_year,
    reason_desc,
    market_manager,
    SUM(return_amt) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    COUNT(DISTINCT order_number) AS distinct_orders,
    SUM(SUM(return_amt)) OVER (
        PARTITION BY return_year
        ORDER BY reason_desc
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_year_reason
FROM enriched
GROUP BY
    return_year,
    reason_desc,
    market_manager
ORDER BY
    total_return_amount DESC
LIMIT 100
