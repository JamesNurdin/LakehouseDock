WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        i.i_category,
        d.d_year,
        d.d_month_seq
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        r.r_reason_desc,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(s.ws_ext_discount_amt) AS total_discount,
    SUM(s.ws_net_profit) AS total_profit,
    SUM(r.wr_return_quantity) AS total_return_qty,
    SUM(r.wr_return_amt) AS total_return_amount,
    SUM(r.wr_net_loss) AS total_return_loss,
    CASE
        WHEN SUM(s.ws_quantity) = 0 THEN 0
        ELSE SUM(r.wr_return_quantity) / SUM(s.ws_quantity)
    END AS return_rate,
    COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
GROUP BY
    s.d_year,
    s.d_month_seq,
    s.i_category
ORDER BY
    s.d_year,
    s.d_month_seq,
    total_sales DESC
LIMIT 100
