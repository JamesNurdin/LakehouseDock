WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        sd.d_year,
        sd.d_month_seq,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        i.i_category,
        CASE WHEN ws.ws_promo_sk IS NOT NULL THEN 'Promoted' ELSE 'Non-Promoted' END AS promotion_flag
    FROM web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE sd.d_date >= DATE '2022-01-01' AND sd.d_date < DATE '2023-01-01'
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_returns wr
    JOIN date_dim rd ON wr.wr_returned_date_sk = rd.d_date_sk
    WHERE rd.d_date >= DATE '2022-01-01' AND rd.d_date < DATE '2023-01-01'
)
SELECT
    s.i_category,
    s.promotion_flag,
    s.d_year,
    s.d_month_seq,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_ext_sales_price) AS total_sales_amount,
    SUM(s.ws_ext_discount_amt) AS total_discount_amount,
    SUM(s.ws_net_profit) AS total_profit,
    COALESCE(SUM(r.wr_return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(r.wr_return_amt), 0) AS total_return_amount,
    CASE
        WHEN SUM(s.ws_quantity) > 0 THEN (COALESCE(SUM(r.wr_return_quantity), 0) * 100.0) / SUM(s.ws_quantity)
        ELSE 0
    END AS return_rate_percent
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
GROUP BY s.i_category, s.promotion_flag, s.d_year, s.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.i_category, s.promotion_flag
