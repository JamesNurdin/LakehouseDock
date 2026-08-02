WITH store_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 7
    GROUP BY i.i_item_id, i.i_product_name, d.d_year, d.d_moy
),
web_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 7
    GROUP BY i.i_item_id, i.i_product_name, d.d_year, d.d_moy
)
SELECT DISTINCT
    item_id,
    product_name,
    year,
    month,
    net_profit,
    'store' AS channel
FROM store_sales_agg
UNION
SELECT DISTINCT
    item_id,
    product_name,
    year,
    month,
    net_profit,
    'web' AS channel
FROM web_sales_agg
ORDER BY net_profit DESC
LIMIT 100
