WITH distinct_return_dates AS (
    SELECT wr.wr_order_number,
           COUNT(DISTINCT wr.wr_returned_date_sk) AS cnt_dates
    FROM web_returns wr
    GROUP BY wr.wr_order_number
)
SELECT
    c.c_customer_id,
    d_sales.d_year,
    d_sales.d_quarter_name,
    i.i_category,
    ws_site.web_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_contribution,
    RANK() OVER (
        PARTITION BY d_sales.d_year
        ORDER BY (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) DESC
    ) AS profit_rank_year,
    ROW_NUMBER() OVER (
        PARTITION BY c.c_customer_id
        ORDER BY d_sales.d_date
    ) AS sale_seq,
    d_cnt.cnt_dates AS distinct_return_dates,
    CASE
        WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred'
        ELSE 'Standard'
    END AS customer_type
FROM web_sales ws
JOIN date_dim d_sales
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON ws.ws_sold_time_sk = t_sales.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN distinct_return_dates d_cnt
    ON ws.ws_order_number = d_cnt.wr_order_number
WHERE d_sales.d_year = 2001
  AND d_sales.d_quarter_seq = 14
  AND i.i_brand = 'Brand#12'
  AND t_sales.t_hour BETWEEN 8 AND 12
  AND ws.ws_ext_sales_price > 1000
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    c.c_customer_id,
    d_sales.d_year,
    d_sales.d_quarter_name,
    i.i_category,
    ws_site.web_name,
    c.c_preferred_cust_flag,
    d_cnt.cnt_dates,
    d_sales.d_date
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY net_contribution DESC
LIMIT 100
