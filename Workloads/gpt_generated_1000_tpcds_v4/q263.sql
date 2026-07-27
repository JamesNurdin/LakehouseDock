WITH profit_by_page AS (
    SELECT wp.wp_type AS wp_type,
           SUM(ws.ws_net_profit) AS total_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_end_date > DATE '2000-01-01'
    GROUP BY wp.wp_type
    HAVING SUM(ws.ws_net_profit) > 10000
),
return_by_page AS (
    SELECT wp.wp_type AS wp_type,
           SUM(wr.wr_return_amt) AS total_amount
    FROM tpcds.web_returns wr
    JOIN tpcds.web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_quantity > 10
    GROUP BY wp.wp_type
    HAVING SUM(wr.wr_return_amt) > 5000
)
SELECT wp_type,
       'profit' AS metric,
       total_amount
FROM profit_by_page
UNION ALL
SELECT wp_type,
       'return' AS metric,
       total_amount
FROM return_by_page
ORDER BY total_amount DESC
LIMIT 100
