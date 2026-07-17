WITH filtered_web_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_city
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE lower(substr(c.c_email_address, strpos(c.c_email_address, '@') + 1)) = 'gmail.com'
      AND lower(CONCAT(c.c_first_name, ' ', c.c_last_name)) LIKE '%a%'
      AND lower(ca.ca_city) LIKE 'san%'
)
SELECT
    ca_state,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_net_profit) AS total_net_profit
FROM filtered_web_sales
GROUP BY ca_state
ORDER BY total_net_profit DESC
