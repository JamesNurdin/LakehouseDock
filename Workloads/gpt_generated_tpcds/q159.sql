WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk,
        d.d_year,
        d.d_moy,
        i.i_brand,
        wp.wp_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM web_returns wr
)
SELECT
    s.d_year,
    s.d_moy,
    s.wp_type,
    s.i_brand,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(s.ws_net_profit) AS total_profit,
    SUM(s.ws_ext_discount_amt) AS total_discount,
    SUM(s.ws_quantity) AS total_quantity,
    COUNT(DISTINCT s.ws_bill_customer_sk) AS distinct_customers,
    COALESCE(SUM(r.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(r.wr_return_quantity), 0) AS total_return_quantity,
    CASE WHEN SUM(s.ws_quantity) = 0 THEN 0
         ELSE COALESCE(SUM(r.wr_return_quantity), 0) * 100.0 / SUM(s.ws_quantity)
    END AS return_rate_percent,
    CASE WHEN SUM(s.ws_ext_sales_price) = 0 THEN 0
         ELSE SUM(s.ws_ext_discount_amt) * 100.0 / SUM(s.ws_ext_sales_price)
    END AS avg_discount_percent
FROM sales s
LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
GROUP BY s.d_year, s.d_moy, s.wp_type, s.i_brand
ORDER BY s.d_year, s.d_moy, total_sales DESC
