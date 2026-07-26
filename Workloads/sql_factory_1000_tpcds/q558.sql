SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state AS billing_state,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) DESC) AS net_profit_rank,
    DENSE_RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS sales_profit_dense_rank,
    CASE WHEN COALESCE(SUM(cr.cr_net_loss), 0) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
FROM
    catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND c.c_customer_sk = cr.cr_refunded_customer_sk
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state
HAVING
    SUM(cs.cs_net_profit) IS NOT NULL
ORDER BY net_profit_after_returns DESC
LIMIT 20
