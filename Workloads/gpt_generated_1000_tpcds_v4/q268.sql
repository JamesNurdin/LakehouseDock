WITH filtered_sales AS (
    SELECT
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_discount_amt,
        ca.ca_state,
        ca.ca_gmt_offset,
        wsit.web_name,
        wsit.web_mkt_class
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ca.ca_gmt_offset = -5.00
      AND ws.ws_ext_wholesale_cost > 5000
      AND wsit.web_country = 'United States'
      AND wsit.web_mkt_class = 'Continuous'
)
SELECT
    web_name,
    ca_state,
    CASE
        WHEN ws_ext_discount_amt > 1000 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_sales_price) AS avg_sales_price,
    COUNT(*) AS order_count,
    MIN(ws_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(ws_ext_wholesale_cost) AS max_wholesale_cost
FROM filtered_sales
GROUP BY
    web_name,
    ca_state,
    CASE
        WHEN ws_ext_discount_amt > 1000 THEN 'High Discount'
        ELSE 'Low Discount'
    END
HAVING SUM(ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
