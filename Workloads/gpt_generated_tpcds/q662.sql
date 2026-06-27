WITH sales_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_net_paid) AS total_sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk
),
returns_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        wr.wr_reason_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_page_sk, wr.wr_reason_sk
)
SELECT
    d_sales.d_date AS sales_date,
    wp.wp_type AS web_page_type,
    reason.r_reason_desc AS return_reason,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.return_cnt, 0) AS return_count
FROM sales_agg s
JOIN date_dim d_sales
    ON s.ws_sold_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON s.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN returns_agg r
    ON s.ws_sold_date_sk = r.ws_sold_date_sk
    AND s.ws_web_page_sk = r.ws_web_page_sk
LEFT JOIN reason
    ON r.wr_reason_sk = reason.r_reason_sk
WHERE d_sales.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
ORDER BY d_sales.d_date, wp.wp_type, reason.r_reason_desc
