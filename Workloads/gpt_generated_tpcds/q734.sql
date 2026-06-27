WITH city_month_sales AS (
    SELECT
        ca.ca_city AS city,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_sales_price) AS sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_city, d.d_year, d.d_moy
)
SELECT
    city,
    year,
    month,
    net_profit,
    sales,
    orders,
    distinct_customers,
    net_profit / NULLIF(sales, 0) AS profit_margin
FROM city_month_sales
ORDER BY net_profit DESC
LIMIT 100
