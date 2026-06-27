WITH sales_dates AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_web_page_sk,
    ws.ws_bill_customer_sk,
    d.d_year,
    d.d_month_seq,
    d.d_date
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
),
returns_dates AS (
  SELECT
    wr.wr_order_number,
    wr.wr_item_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    d.d_year AS return_year,
    d.d_month_seq AS return_month_seq,
    d.d_date AS return_date
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
)
SELECT
  sd.d_year,
  sd.d_month_seq,
  wp.wp_type,
  sum(sd.ws_net_paid) AS total_net_paid,
  sum(sd.ws_net_profit) AS total_net_profit,
  sum(coalesce(rd.wr_return_amt, 0)) AS total_return_amount,
  sum(coalesce(rd.wr_net_loss, 0)) AS total_return_loss,
  sum(sd.ws_net_paid) - sum(coalesce(rd.wr_return_amt, 0)) AS net_paid_after_returns,
  count(distinct sd.ws_bill_customer_sk) AS distinct_preferred_customers
FROM sales_dates sd
LEFT JOIN returns_dates rd
  ON sd.ws_order_number = rd.wr_order_number
  AND sd.ws_item_sk = rd.wr_item_sk
JOIN web_page wp
  ON sd.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c
  ON sd.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND sd.d_year BETWEEN 1998 AND 1999
GROUP BY
  sd.d_year,
  sd.d_month_seq,
  wp.wp_type
ORDER BY
  sd.d_year,
  sd.d_month_seq,
  wp.wp_type
