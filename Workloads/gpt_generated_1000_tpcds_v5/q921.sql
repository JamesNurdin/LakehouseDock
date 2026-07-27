WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        td.t_hour,
        SUM(ss.ss_net_paid)               AS total_net_paid,
        SUM(ss.ss_net_profit)             AS total_net_profit,
        wp.wp_web_page_sk,
        wp.wp_image_count
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour IN (3, 15, 17)
      AND wp.wp_image_count > 3
      AND ss.ss_net_profit > 0
    GROUP BY ss.ss_store_sk, td.t_hour, wp.wp_web_page_sk, wp.wp_image_count
)
SELECT
    sa.ss_store_sk,
    sa.t_hour,
    sa.total_net_paid,
    sa.total_net_profit,
    (
        SELECT AVG(wr2.wr_return_amt_inc_tax)
        FROM web_returns wr2
        WHERE wr2.wr_web_page_sk = sa.wp_web_page_sk
    ) AS avg_return_amt_inc_tax,
    RANK() OVER (PARTITION BY sa.t_hour ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM sales_agg sa
ORDER BY profit_rank, sa.total_net_profit DESC
LIMIT 100
