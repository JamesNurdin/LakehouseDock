WITH monthly_profit AS (
    SELECT
        cs.cs_call_center_sk AS cc_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_date_sk
)
SELECT
    cc_sk,
    sold_date_sk,
    total_sales_profit,
    total_return_loss,
    net_profit,
    LAG(net_profit) OVER (PARTITION BY cc_sk ORDER BY sold_date_sk) AS prev_month_net_profit,
    CASE 
        WHEN LAG(net_profit) OVER (PARTITION BY cc_sk ORDER BY sold_date_sk) = 0 THEN NULL
        ELSE (net_profit - LAG(net_profit) OVER (PARTITION BY cc_sk ORDER BY sold_date_sk))
             / NULLIF(LAG(net_profit) OVER (PARTITION BY cc_sk ORDER BY sold_date_sk), 0) * 100.0
    END AS month_over_month_growth_percent,
    RANK() OVER (PARTITION BY cc_sk ORDER BY net_profit DESC) AS month_profit_rank
FROM monthly_profit
ORDER BY cc_sk, sold_date_sk
