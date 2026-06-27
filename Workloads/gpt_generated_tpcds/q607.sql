WITH sales AS (
    SELECT
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_location_type AS location_type,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
    UNION ALL
    SELECT
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_location_type AS location_type,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country = 'United States'
)
SELECT
    city,
    state,
    location_type,
    sales_channel,
    SUM(quantity) AS total_quantity,
    SUM(discount_amt) AS total_discount_amount,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    AVG(net_paid) AS avg_net_paid,
    COUNT(*) AS sales_count
FROM sales
GROUP BY city, state, location_type, sales_channel
ORDER BY total_net_profit DESC
LIMIT 100
