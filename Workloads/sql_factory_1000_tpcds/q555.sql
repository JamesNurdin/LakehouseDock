WITH state_stats AS (
    SELECT
        ca.ca_state,
        COUNT(*) AS total_sales,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_net_profit) / COUNT(*) AS avg_profit_per_sale
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY ca.ca_state
)
SELECT
    ca_state,
    total_sales,
    total_return_loss,
    total_sales_profit,
    avg_profit_per_sale,
    CASE WHEN avg_profit_per_sale > 100 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (ORDER BY avg_profit_per_sale DESC) AS profit_rank
FROM state_stats
ORDER BY profit_rank
LIMIT 10
