SELECT
    cs.cs_item_sk,
    SUM(cs.cs_quantity) AS total_sold_qty,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_qty,
    CASE 
        WHEN SUM(cs.cs_quantity) = 0 THEN 0
        ELSE COALESCE(SUM(cr.cr_return_quantity), 0) * 100.0 / SUM(cs.cs_quantity)
    END AS return_rate_percent,
    SUM(cs.cs_net_paid) AS total_sales_revenue,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_revenue_after_returns,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    COUNT(DISTINCT ca.ca_state) AS distinct_states,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_quantity) DESC) AS quantity_rank
FROM
    catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
WHERE
    cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
GROUP BY
    cs.cs_item_sk
HAVING
    SUM(cs.cs_quantity) >= 10
ORDER BY net_revenue_after_returns DESC
LIMIT 10
