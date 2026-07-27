WITH sales_with_threshold AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_web_site_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_sales_price > (
        SELECT AVG(ws2.ws_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
    )
)
SELECT
    ws.ws_web_site_sk,
    web_site.web_name,
    customer_address.ca_state,
    CASE
        WHEN web_returns.wr_return_quantity > 1 THEN 'Multiple'
        ELSE 'Single'
    END AS return_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS avg_sales,
    SUM(web_returns.wr_return_amt) AS total_return_amount,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM sales_with_threshold ws
JOIN customer
    ON ws.ws_bill_customer_sk = customer.c_customer_sk
JOIN customer_address
    ON ws.ws_bill_addr_sk = customer_address.ca_address_sk
JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN web_returns
    ON web_returns.wr_order_number = ws.ws_order_number
JOIN reason
    ON web_returns.wr_reason_sk = reason.r_reason_sk
WHERE
    customer.c_birth_country = 'United States'
    AND customer_address.ca_state = 'CA'
    AND web_site.web_market_manager = 'James Bernard'
    AND ws.ws_sales_price BETWEEN 50 AND 200
    AND reason.r_reason_desc LIKE '%damaged%'
GROUP BY
    ws.ws_web_site_sk,
    web_site.web_name,
    customer_address.ca_state,
    CASE
        WHEN web_returns.wr_return_quantity > 1 THEN 'Multiple'
        ELSE 'Single'
    END
ORDER BY total_sales DESC
LIMIT 100
