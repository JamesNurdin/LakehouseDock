WITH all_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_ext_sales_price AS sales_amount,
           ss.ss_ext_discount_amt AS discount_amount,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ticket_number AS order_number,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_bill_customer_sk,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           ws.ws_ext_discount_amt,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_order_number,
           'web'
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_bill_customer_sk,
           cs.cs_item_sk,
           cs.cs_ext_sales_price,
           cs.cs_ext_discount_amt,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_order_number,
           'catalog'
    FROM catalog_sales cs
),
all_returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_refunded_customer_sk AS customer_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS return_qty,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_amount AS return_amount,
           cr.cr_order_number AS order_number,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_customer_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_net_loss,
           sr.sr_return_amt,
           sr.sr_ticket_number,
           'store'
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_refunded_customer_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_net_loss,
           wr.wr_return_amt,
           wr.wr_order_number,
           'web'
    FROM web_returns wr
),
sales_agg AS (
    SELECT d.d_year,
           s.customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           SUM(s.net_profit) AS total_profit,
           SUM(s.sales_amount) AS total_sales,
           COUNT(DISTINCT s.order_number) AS orders_cnt
    FROM all_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    GROUP BY d.d_year, s.customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
returns_agg AS (
    SELECT d.d_year,
           r.customer_sk,
           SUM(r.net_loss) AS total_loss,
           COUNT(DISTINCT r.order_number) AS return_cnt
    FROM all_returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    GROUP BY d.d_year, r.customer_sk
),
customer_profit AS (
    SELECT sa.d_year,
           sa.customer_sk,
           sa.c_first_name,
           sa.c_last_name,
           sa.c_email_address,
           sa.total_profit,
           sa.total_sales,
           COALESCE(ra.total_loss, 0) AS total_loss,
           (sa.total_profit - COALESCE(ra.total_loss, 0)) AS net_profit,
           sa.orders_cnt,
           COALESCE(ra.return_cnt, 0) AS return_cnt,
           RANK() OVER (PARTITION BY sa.d_year ORDER BY (sa.total_profit - COALESCE(ra.total_loss, 0)) DESC) AS profit_rank
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.d_year = ra.d_year AND sa.customer_sk = ra.customer_sk
),
top_customers AS (
    SELECT *
    FROM customer_profit
    WHERE profit_rank <= 5
),
avg_year_profit AS (
    SELECT d_year,
           AVG(net_profit) AS avg_net_profit_per_customer
    FROM customer_profit
    GROUP BY d_year
)
SELECT tc.d_year,
       tc.customer_sk,
       tc.c_first_name,
       tc.c_last_name,
       tc.c_email_address,
       tc.net_profit,
       tc.total_sales,
       tc.total_loss,
       tc.orders_cnt,
       tc.return_cnt,
       tc.profit_rank,
       ay.avg_net_profit_per_customer
FROM top_customers tc
JOIN avg_year_profit ay
    ON tc.d_year = ay.d_year
ORDER BY tc.d_year, tc.profit_rank
