WITH catalog_sales_daily AS (
    SELECT
        'catalog' AS sales_channel,
        d.d_date AS sale_date,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        l.total_qty_by_date AS daily_total_quantity,
        (
            SELECT SUM(cs3.cs_net_profit)
            FROM catalog_sales cs3
            WHERE cs3.cs_bill_customer_sk = cs.cs_bill_customer_sk
        ) AS cust_total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT SUM(cs2.cs_quantity) AS total_qty_by_date
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
    ) AS l
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-03-31'
),
web_sales_daily AS (
    SELECT
        'web' AS sales_channel,
        d.d_date AS sale_date,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        l.total_qty_by_date AS daily_total_quantity,
        (
            SELECT SUM(ws3.ws_net_profit)
            FROM web_sales ws3
            WHERE ws3.ws_bill_customer_sk = ws.ws_bill_customer_sk
        ) AS cust_total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_quantity) AS total_qty_by_date
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk
    ) AS l
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-03-31'
)
SELECT
    sales_channel,
    sale_date,
    quantity,
    net_profit,
    daily_total_quantity,
    cust_total_profit
FROM (
    SELECT
        sales_channel,
        sale_date,
        quantity,
        net_profit,
        daily_total_quantity,
        cust_total_profit
    FROM catalog_sales_daily
    UNION ALL
    SELECT
        sales_channel,
        sale_date,
        quantity,
        net_profit,
        daily_total_quantity,
        cust_total_profit
    FROM web_sales_daily
) AS combined
ORDER BY sale_date, sales_channel
LIMIT 100
