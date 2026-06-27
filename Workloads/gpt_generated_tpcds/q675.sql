WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        i.i_category,
        d_sold.d_year,
        d_sold.d_month_seq
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
)
SELECT
    sales.i_category,
    sales.d_year,
    sales.d_month_seq,
    sum(sales.ws_net_paid) AS total_net_paid,
    sum(sales.ws_net_profit) AS total_net_profit,
    sum(coalesce(wr.wr_return_amt, 0)) AS total_return_amount,
    sum(coalesce(wr.wr_net_loss, 0)) AS total_return_loss,
    (sum(sales.ws_net_profit) - sum(coalesce(wr.wr_net_loss, 0))) AS net_profit_after_returns,
    sum(sales.ws_ext_discount_amt) AS total_discount_amount,
    sum(sales.ws_ext_sales_price) AS total_sales_price,
    (sum(sales.ws_ext_discount_amt) / nullif(sum(sales.ws_ext_sales_price), 0)) * 100 AS discount_percent,
    ((sum(sales.ws_net_profit) - sum(coalesce(wr.wr_net_loss, 0))) / nullif(sum(sales.ws_ext_sales_price), 0)) * 100 AS net_margin_percent
FROM sales
LEFT JOIN web_returns wr
    ON sales.ws_order_number = wr.wr_order_number
    AND sales.ws_item_sk = wr.wr_item_sk
GROUP BY
    sales.i_category,
    sales.d_year,
    sales.d_month_seq
HAVING sum(sales.ws_net_paid) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
