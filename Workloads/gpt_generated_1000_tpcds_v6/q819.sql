WITH sales_by_state AS (
    SELECT
        ca.ca_state AS state,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category
    FROM tpcds.web_sales ws
    INNER JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT OUTER JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE c.c_birth_month IN (1, 2, 3, 4)
      AND c.c_birth_day BETWEEN 10 AND 28
      AND ws.ws_wholesale_cost > 45.00
      AND ws.ws_ship_cdemo_sk IS NOT NULL
    GROUP BY ca.ca_state
)
SELECT
    sb.state,
    sb.orders,
    sb.total_sales,
    sb.total_profit,
    sb.sales_category,
    ROUND(sb.total_profit / NULLIF(sb.total_sales, 0), 4) AS profit_margin
FROM sales_by_state sb
WHERE sb.total_sales > 50000
ORDER BY profit_margin DESC
LIMIT 100
