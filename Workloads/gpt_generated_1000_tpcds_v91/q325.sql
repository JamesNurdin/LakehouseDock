WITH orders_without_returns AS (
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
    EXCEPT
    SELECT wr.wr_order_number AS order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
)
SELECT
    d.d_date,
    wsite.web_site_id,
    ws.ws_order_number,
    ws.ws_sales_price,
    ws.ws_quantity,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    SUM(ws.ws_net_profit) OVER (
        PARTITION BY wsite.web_site_id
        ORDER BY d.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net_profit,
    ROW_NUMBER() OVER (
        PARTITION BY wsite.web_site_id
        ORDER BY ws.ws_net_profit DESC
    ) AS profit_rank,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
    ) AS total_return_amt
FROM
    date_dim d
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN orders_without_returns owr ON owr.order_number = ws.ws_order_number
WHERE
    d.d_year = 2001
    AND hd.hd_income_band_sk IN (6, 12, 13)
    AND r.r_reason_id = 'AAAAAAAANAAAAAAA'
    AND ws.ws_sales_price BETWEEN 20 AND 100
ORDER BY
    wsite.web_site_id,
    running_net_profit DESC
LIMIT 100
