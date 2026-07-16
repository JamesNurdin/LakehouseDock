WITH catalog AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_year AS sales_year,
        sum(cs.cs_net_profit) AS profit,
        sum(cs.cs_ext_sales_price) AS sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_item_sk, d.d_year
),
store AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_year AS sales_year,
        sum(ss.ss_net_profit) AS profit,
        sum(ss.ss_ext_sales_price) AS sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_item_sk, d.d_year
),
web AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        d.d_year AS sales_year,
        sum(ws.ws_net_profit) AS profit,
        sum(ws.ws_ext_sales_price) AS sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_item_sk, d.d_year
),
combined AS (
    SELECT item_sk, sales_year, profit, sales FROM catalog
    UNION ALL
    SELECT item_sk, sales_year, profit, sales FROM store
    UNION ALL
    SELECT item_sk, sales_year, profit, sales FROM web
)
SELECT
    i.i_item_id,
    i.i_product_name,
    sum(c.profit) AS total_profit,
    sum(c.sales) AS total_sales,
    c.sales_year
FROM combined c
JOIN item i ON c.item_sk = i.i_item_sk
GROUP BY i.i_item_id, i.i_product_name, c.sales_year
ORDER BY total_profit DESC
LIMIT 100
