WITH base_returns AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_return_tax,
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        wr.wr_web_page_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_tax > 0
      AND c.c_preferred_cust_flag = 'Y'
      AND wp.wp_autogen_flag = 'N'
)
SELECT *
FROM (
    SELECT
        i.i_category AS category,
        CAST(NULL AS VARCHAR) AS page_type,
        td.t_hour AS hour,
        SUM(br.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM base_returns br
    JOIN item i ON br.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON br.wr_returned_time_sk = td.t_time_sk
    GROUP BY ROLLUP (i.i_category, td.t_hour)

    UNION ALL

    SELECT
        CAST(NULL AS VARCHAR) AS category,
        wp.wp_type AS page_type,
        td.t_hour AS hour,
        SUM(br.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM base_returns br
    JOIN web_page wp ON br.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td ON br.wr_returned_time_sk = td.t_time_sk
    GROUP BY ROLLUP (wp.wp_type, td.t_hour)
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
