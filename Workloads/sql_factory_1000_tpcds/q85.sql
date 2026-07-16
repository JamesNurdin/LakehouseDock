WITH combined AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_profit BETWEEN 0 AND 500
    UNION ALL
    SELECT
        ca.ca_state,
        ca.ca_city,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_image_count > 3
),
agg AS (
    SELECT
        ca_state,
        ca_city,
        SUM(profit) AS total_profit,
        AVG(discount_amt) AS avg_discount
    FROM combined
    GROUP BY ca_state, ca_city
)
SELECT
    ca_state,
    ca_city,
    total_profit,
    avg_discount,
    NTILE(4) OVER (ORDER BY total_profit DESC) AS profit_quartile,
    SUM(total_profit) OVER (PARTITION BY ca_state) AS state_total_profit
FROM agg
WHERE total_profit > 0
ORDER BY total_profit DESC
LIMIT 25
