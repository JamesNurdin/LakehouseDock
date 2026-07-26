SELECT
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    SUM(cs.cs_net_profit) AS sales_profit,
    SUM(cr.cr_net_loss) AS return_loss,
    (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_item_profit,
    CASE
        WHEN (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_indicator,
    RANK() OVER (PARTITION BY cs.cs_call_center_sk ORDER BY (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) DESC) AS call_center_item_rank,
    DENSE_RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) DESC) AS overall_item_rank
FROM catalog_sales cs
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
GROUP BY cs.cs_item_sk, cs.cs_call_center_sk
HAVING SUM(cs.cs_net_profit) IS NOT NULL
ORDER BY net_item_profit DESC
LIMIT 10
