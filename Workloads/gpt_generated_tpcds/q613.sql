/*
  Analytical query: total net profit and quantity by year, month and item category
  across store, catalog and web sales channels for the period 1999‑01‑01 to 2001‑12‑31.
*/
WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
)
SELECT
    year,
    month,
    category,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity)   AS total_quantity
FROM (
    SELECT d_year AS year, d_moy AS month, i_category AS category, ss_net_profit AS net_profit, ss_quantity AS quantity
    FROM store_sales_agg
    UNION ALL
    SELECT d_year AS year, d_moy AS month, i_category AS category, cs_net_profit AS net_profit, cs_quantity AS quantity
    FROM catalog_sales_agg
    UNION ALL
    SELECT d_year AS year, d_moy AS month, i_category AS category, ws_net_profit AS net_profit, ws_quantity AS quantity
    FROM web_sales_agg
) AS combined
GROUP BY year, month, category
ORDER BY year, month, total_net_profit DESC
