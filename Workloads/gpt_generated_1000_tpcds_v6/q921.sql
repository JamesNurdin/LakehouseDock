WITH returns_with_page AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wp.wp_url,
        wp.wp_type,
        wp.wp_autogen_flag,
        wp.wp_link_count,
        regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1) AS domain,
        t.t_hour
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]+/sports/.*')
      AND wp.wp_autogen_flag = 'N'
      AND wp.wp_link_count > 5
),
agg_returns AS (
    SELECT
        wp_type,
        t_hour,
        MAX(domain) AS domain,
        SUM(wr_net_loss) AS total_net_loss,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        MIN(wr_returned_date_sk) AS min_date_sk
    FROM returns_with_page
    GROUP BY wp_type, t_hour
)
SELECT
    a.wp_type,
    a.t_hour,
    a.domain,
    a.total_net_loss,
    a.total_return_amt,
    a.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.wp_type ORDER BY a.total_net_loss DESC) AS rank_within_type,
    substring(a.wp_type FROM 1 FOR 3) AS type_prefix,
    (
        SELECT COUNT(*)
        FROM store_sales ss
        JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
        WHERE t2.t_hour = a.t_hour
          AND ss.ss_sold_date_sk = a.min_date_sk
    ) AS sales_on_same_day_hour
FROM agg_returns a
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
    WHERE t2.t_hour = a.t_hour
      AND ss.ss_store_sk IS NOT NULL
)
ORDER BY a.total_net_loss DESC
LIMIT 100
