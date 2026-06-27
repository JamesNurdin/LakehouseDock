WITH sales AS (
    SELECT
        ws.ws_order_number,
        d.d_month_seq,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_web_page_sk
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_reason_sk
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
)
SELECT
    s.d_month_seq AS month_seq,
    COALESCE(r.r_reason_desc, 'No Return') AS return_reason,
    SUM(s.ws_ext_sales_price) AS total_sales_amount,
    SUM(s.ws_quantity) AS total_sales_quantity,
    SUM(COALESCE(rt.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(rt.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(s.ws_net_profit) - SUM(COALESCE(rt.wr_net_loss, 0)) AS net_profit,
    CASE
        WHEN SUM(s.ws_quantity) = 0 THEN 0
        ELSE 100.0 * SUM(COALESCE(rt.wr_return_quantity, 0)) / SUM(s.ws_quantity)
    END AS return_rate_percent,
    AVG(s.ws_ext_discount_amt) AS avg_discount_amount,
    AVG(wp.wp_char_count) AS avg_page_char_count
FROM sales s
LEFT JOIN returns rt
    ON s.ws_order_number = rt.wr_order_number
LEFT JOIN reason r
    ON rt.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp
    ON s.ws_web_page_sk = wp.wp_web_page_sk
GROUP BY s.d_month_seq, r.r_reason_desc
ORDER BY s.d_month_seq, total_sales_amount DESC
