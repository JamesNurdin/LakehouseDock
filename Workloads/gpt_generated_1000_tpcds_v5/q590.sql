WITH recent_customers AS (
    SELECT c_customer_sk,
           c_email_address,
           c_first_sales_date_sk
    FROM   customer
    WHERE  c_first_sales_date_sk >= 2450690
)
SELECT customer_sk,
       email,
       return_cnt,
       total_net_loss,
       loss_category,
       avg_return_amt_for_page
FROM (
    SELECT rc.c_customer_sk AS customer_sk,
           rc.c_email_address AS email,
           COUNT(*) AS return_cnt,
           SUM(wr.wr_net_loss) AS total_net_loss,
           CASE
               WHEN SUM(wr.wr_net_loss) > 1000 THEN 'HIGH'
               WHEN SUM(wr.wr_net_loss) BETWEEN 500 AND 1000 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS loss_category,
           (SELECT AVG(wr2.wr_return_amt)
            FROM   web_returns wr2
            WHERE  wr2.wr_web_page_sk = wr.wr_web_page_sk) AS avg_return_amt_for_page
    FROM   recent_customers rc
    JOIN   web_returns wr
           ON wr.wr_refunded_customer_sk = rc.c_customer_sk
    WHERE  wr.wr_return_ship_cost > 200
      AND  wr.wr_web_page_sk IN (2809, 2413)
    GROUP BY rc.c_customer_sk,
             rc.c_email_address,
             wr.wr_web_page_sk
    UNION ALL
    SELECT rc.c_customer_sk AS customer_sk,
           rc.c_email_address AS email,
           COUNT(*) AS return_cnt,
           SUM(wr.wr_net_loss) AS total_net_loss,
           CASE
               WHEN SUM(wr.wr_net_loss) > 800 THEN 'HIGH'
               WHEN SUM(wr.wr_net_loss) BETWEEN 300 AND 800 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS loss_category,
           (SELECT AVG(wr2.wr_return_amt)
            FROM   web_returns wr2
            WHERE  wr2.wr_web_page_sk = wr.wr_web_page_sk) AS avg_return_amt_for_page
    FROM   recent_customers rc
    JOIN   web_returns wr
           ON wr.wr_returning_customer_sk = rc.c_customer_sk
    WHERE  wr.wr_return_ship_cost BETWEEN 100 AND 500
      AND  wr.wr_web_page_sk = 2836
    GROUP BY rc.c_customer_sk,
             rc.c_email_address,
             wr.wr_web_page_sk
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
