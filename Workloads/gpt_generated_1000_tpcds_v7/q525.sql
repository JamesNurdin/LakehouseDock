WITH ws_base AS (
    SELECT *
    FROM web_sales ws
)
SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    i.i_category,
    p.p_promo_name,
    cust_bill.c_first_name || ' ' || cust_bill.c_last_name AS bill_customer_name,
    cd_bill.cd_gender,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    COUNT(DISTINCT wr.wr_order_number) AS returns,
    SUM(CASE WHEN r.r_reason_desc LIKE '%color%' THEN wr.wr_return_amt ELSE 0 END) AS color_returns
FROM ws_base ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer cust_bill
  ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
  ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer cust_refund
  ON wr.wr_refunded_customer_sk = cust_refund.c_customer_sk
JOIN customer_demographics cd_refund
  ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
WHERE d_sold.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND r.r_reason_desc LIKE '%color%'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_category,
    p.p_promo_name,
    cust_bill.c_first_name,
    cust_bill.c_last_name,
    cd_bill.cd_gender
ORDER BY total_sales DESC
LIMIT 100
