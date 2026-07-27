WITH page_sales AS (
    SELECT
        wp.wp_type,
        wp.wp_url,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS sales_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales ws
        INNER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_link_count > 5
        AND wp.wp_char_count BETWEEN 1000 AND 8000
        AND wp.wp_rec_end_date >= DATE '1999-01-01'
        AND ws.ws_sales_price > 10
        AND ws.ws_quantity >= 1
        AND ws.ws_ship_cdemo_sk IN (1630659, 257323, 67833)
    GROUP BY
        wp.wp_type,
        wp.wp_url
)
SELECT
    ps.wp_type,
    ps.wp_url,
    ps.total_profit,
    ps.total_quantity,
    ps.sales_count,
    ps.avg_sales_price,
    ps.total_profit / NULLIF(ps.total_quantity, 0) AS profit_per_item,
    RANK() OVER (ORDER BY ps.total_profit DESC) AS profit_rank
FROM
    page_sales ps
WHERE
    ps.total_profit > (
        SELECT AVG(total_profit) FROM page_sales
    )
ORDER BY
    profit_rank
LIMIT 10
