SELECT order_number
FROM (
    SELECT cs.cs_order_number AS order_number
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cr.cr_return_amount > 100
    GROUP BY cs.cs_order_number
) 
INTERSECT
SELECT order_number
FROM (
    SELECT ss.ss_ticket_number AS order_number
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_sold.d_year = 2001
      AND sr.sr_net_loss > 100
    GROUP BY ss.ss_ticket_number
)
ORDER BY order_number DESC
LIMIT 100
