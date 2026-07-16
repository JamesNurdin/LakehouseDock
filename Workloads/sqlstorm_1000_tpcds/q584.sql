WITH sales_union AS (
  SELECT d.d_year AS year,
         cs.cs_bill_customer_sk AS cust_sk,
         c.c_customer_id,
         c.c_first_name,
         c.c_last_name,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         cs.cs_ext_discount_amt AS discount_amount,
         cs.cs_ext_sales_price AS sales_price
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  UNION ALL
  SELECT d.d_year,
         ss.ss_customer_sk,
         c.c_customer_id,
         c.c_first_name,
         c.c_last_name,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         ss.ss_ext_discount_amt,
         ss.ss_ext_sales_price
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  UNION ALL
  SELECT d.d_year,
         ws.ws_bill_customer_sk,
         c.c_customer_id,
         c.c_first_name,
         c.c_last_name,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         ws.ws_ext_discount_amt,
         ws.ws_ext_sales_price
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
sales_agg AS (
  SELECT
    year,
    cust_sk,
    c_customer_id AS cust_id,
    concat(c_first_name, ' ', c_last_name) AS cust_name,
    SUM(quantity) AS total_quantity_sold,
    SUM(net_paid) AS total_sales_amount,
    SUM(net_profit) AS total_sales_profit,
    SUM(discount_amount) AS total_discount_amount,
    SUM(sales_price) AS total_sales_price
  FROM sales_union
  GROUP BY year, cust_sk, c_customer_id, c_first_name, c_last_name
),
returns_union AS (
  SELECT d.d_year AS year,
         cr.cr_refunded_customer_sk AS cust_sk,
         c.c_customer_id,
         cr.cr_return_quantity AS quantity,
         cr.cr_return_amount AS return_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  UNION ALL
  SELECT d.d_year,
         sr.sr_customer_sk,
         c.c_customer_id,
         sr.sr_return_quantity,
         sr.sr_return_amt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  UNION ALL
  SELECT d.d_year,
         wr.wr_refunded_customer_sk,
         c.c_customer_id,
         wr.wr_return_quantity,
         wr.wr_return_amt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
),
returns_agg AS (
  SELECT
    year,
    cust_sk,
    c_customer_id AS cust_id,
    SUM(quantity) AS total_quantity_returned,
    SUM(return_amount) AS total_return_amount
  FROM returns_union
  GROUP BY year, cust_sk, c_customer_id
),
final AS (
  SELECT
    s.year,
    s.cust_id,
    s.cust_name,
    s.total_quantity_sold,
    s.total_sales_amount,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_revenue,
    s.total_sales_profit - COALESCE(r.total_return_amount * 0.5, 0) AS net_profit_adj,
    CASE WHEN s.total_sales_price = 0 THEN 0
         ELSE s.total_discount_amount / s.total_sales_price END AS discount_rate
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.year = r.year
   AND s.cust_sk = r.cust_sk
)
SELECT
  year,
  cust_id,
  cust_name,
  total_quantity_sold,
  total_sales_amount,
  total_return_amount,
  net_revenue,
  net_profit_adj,
  discount_rate,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY net_revenue DESC) AS revenue_rank
FROM final
WHERE year = 2001
ORDER BY net_revenue DESC
LIMIT 10
