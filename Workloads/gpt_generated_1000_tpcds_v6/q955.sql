/*
Goal: Identify the top web pages by total return amount, showing the reason for returns, categorising the return magnitude, and ranking pages within each URL. The query pre‑aggregates web_returns, then joins to web_sales, web_page and reason, applying multiple filters and a window rank.
*/
WITH return_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_reason_sk,
        SUM(wr.wr_return_amt)        AS total_return_amt,
        COUNT(*)                     AS return_cnt,
        SUM(wr.wr_net_loss)          AS total_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_amt      > 100
      AND wr.wr_fee              > 20
      AND wr.wr_return_ship_cost < 5000
      AND wr.wr_reason_sk        IS NOT NULL
    GROUP BY wr.wr_order_number, wr.wr_reason_sk
)
SELECT
    ws.ws_order_number,
    wp.wp_url,
    r.r_reason_desc,
    ra.total_return_amt,
    ra.return_cnt,
    CASE
        WHEN ra.total_return_amt > 500 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    ws.ws_net_profit,
    RANK() OVER (PARTITION BY wp.wp_url ORDER BY ra.total_return_amt DESC) AS return_rank_per_page
FROM return_agg ra
JOIN web_sales ws
    ON ra.wr_order_number = ws.ws_order_number
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN reason r
    ON ra.wr_reason_sk = r.r_reason_sk
WHERE wp.wp_type                = 'Content'
  AND ws.ws_quantity            >= 2
  AND ws.ws_ship_customer_sk    > 5000000
  AND r.r_reason_id             = 'AAAAAAAAMAAAAAAA'
ORDER BY ra.total_return_amt DESC
LIMIT 100
