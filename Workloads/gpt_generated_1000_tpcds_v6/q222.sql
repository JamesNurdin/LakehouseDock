WITH sales_returns_a AS (
    SELECT
        wp.wp_web_page_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amt,
        CASE WHEN SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) > 0
            THEN SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0)
            ELSE 0
        END AS net_sales,
        CASE WHEN COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    WHERE wp.wp_web_page_id = 'AAAAAAAAABAAAAAA'
      AND ws.ws_quantity > 1
    GROUP BY wp.wp_web_page_id
),
sales_returns_b AS (
    SELECT
        wp.wp_web_page_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amt,
        CASE WHEN SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) > 0
            THEN SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0)
            ELSE 0
        END AS net_sales,
        CASE WHEN COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.web_returns wr
        ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    WHERE wp.wp_web_page_id = 'AAAAAAAAPBAAAAAA'
      AND ws.ws_quantity <= 2
    GROUP BY wp.wp_web_page_id
)
SELECT
    u.wp_web_page_id,
    u.total_sales,
    u.total_return_amt,
    u.net_sales,
    u.return_flag
FROM (
    SELECT * FROM sales_returns_a
    UNION ALL
    SELECT * FROM sales_returns_b
) AS u
ORDER BY u.net_sales DESC
LIMIT 100
