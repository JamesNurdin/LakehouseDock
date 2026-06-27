WITH sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    sum(s.ws_ext_sales_price) AS total_sales,
    sum(s.ws_net_profit) AS total_profit,
    sum(coalesce(r.wr_return_amt, 0)) AS total_returns,
    CASE WHEN sum(s.ws_ext_sales_price) = 0 THEN 0
         ELSE sum(coalesce(r.wr_return_amt, 0)) / sum(s.ws_ext_sales_price)
    END AS return_rate
FROM sales s
JOIN date_dim d
  ON s.ws_sold_date_sk = d.d_date_sk
JOIN item i
  ON s.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns r
  ON r.wr_order_number = s.ws_order_number
 AND r.wr_item_sk = s.ws_item_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category
ORDER BY
    d.d_year,
    d.d_month_seq,
    i.i_category
