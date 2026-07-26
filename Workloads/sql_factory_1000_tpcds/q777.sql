SELECT
    c.c_customer_id,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_balance,
    SUM(wp.wp_char_count) AS total_char_count,
    CASE
        WHEN SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) BETWEEN 0 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) DESC) AS profit_rank
FROM customer c
LEFT JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
HAVING SUM(cs.cs_net_profit) IS NOT NULL
ORDER BY net_balance DESC
LIMIT 10
