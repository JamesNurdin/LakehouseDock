WITH high_page AS (
    SELECT max(wr_web_page_sk) AS max_sk
    FROM web_returns
    WHERE wr_return_amt > 500
)
SELECT
    combined.wp_type,
    combined.total_return_amount,
    combined.avg_return_quantity,
    (SELECT wp_max_ad_count
     FROM web_page wp3
     WHERE wp3.wp_web_page_sk = (SELECT max_sk FROM high_page)) AS high_page_max_ad
FROM (
    SELECT
        wp.wp_type,
        sum(wr.wr_return_amt) AS total_return_amount,
        avg(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wr.wr_return_amt > 1000
    GROUP BY wp.wp_type
    HAVING sum(wr.wr_return_amt) > 2000

    UNION ALL

    SELECT
        wp.wp_type,
        sum(wr.wr_return_amt) AS total_return_amount,
        avg(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wr.wr_return_ship_cost > 300
    GROUP BY wp.wp_type
    HAVING avg(wr.wr_return_quantity) > 2
) AS combined
ORDER BY combined.total_return_amount DESC
LIMIT 100
