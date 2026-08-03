WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT order_number,
       profit_category,
       running_net_paid
FROM (
    SELECT cs.cs_order_number AS order_number,
           CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
           SUM(cs.cs_net_paid) OVER (PARTITION BY cs.cs_bill_customer_sk
                                      ORDER BY cs.cs_sold_date_sk
                                      ROWS UNBOUNDED PRECEDING) AS running_net_paid
    FROM catalog_sales cs
    JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_quantity > 0
) AS a
INTERSECT
SELECT order_number,
       profit_category,
       running_net_paid
FROM (
    SELECT cs.cs_order_number AS order_number,
           CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
           SUM(cs.cs_net_paid) OVER (PARTITION BY cs.cs_bill_customer_sk
                                      ORDER BY cs.cs_sold_date_sk
                                      ROWS UNBOUNDED PRECEDING) AS running_net_paid
    FROM catalog_sales cs
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    WHERE cr.cr_return_quantity > 0
) AS b
LIMIT 100
