WITH sales_by_state_site AS (
    SELECT
        ca.ca_state,
        wsit.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE
        ca.ca_state IN ('CA', 'TX', 'NY')
        AND ca.ca_county LIKE '%County'
        AND ws.ws_net_paid_inc_tax > 1000
        AND ws.ws_quantity >= 2
        AND wsit.web_company_id IN (1, 3, 5)
        AND wsit.web_street_name LIKE 'Cherry%'
    GROUP BY
        ca.ca_state,
        wsit.web_name
)
SELECT
    ca_state,
    AVG(total_profit) AS avg_profit_per_site,
    SUM(total_sales) AS total_sales_state,
    SUM(order_cnt) AS total_orders_state
FROM sales_by_state_site
GROUP BY ca_state
HAVING AVG(total_profit) > 5000
ORDER BY avg_profit_per_site DESC
