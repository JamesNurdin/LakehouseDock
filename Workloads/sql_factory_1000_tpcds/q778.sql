SELECT
    cs.cs_call_center_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_profit,
    CASE
        WHEN (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) > 0 THEN 'POSITIVE'
        ELSE 'NEGATIVE'
    END AS profit_status,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(wp.wp_char_count) AS total_char_count,
    RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) DESC) AS profit_rank
FROM catalog_sales cs
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk
HAVING SUM(cs.cs_net_profit) IS NOT NULL
ORDER BY net_profit DESC
LIMIT 5
