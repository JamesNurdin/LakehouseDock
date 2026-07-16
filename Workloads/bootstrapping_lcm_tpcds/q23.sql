WITH cs_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        COUNT(*) AS cs_transactions,
        SUM(cs.cs_sales_price) AS cs_total_sales,
        SUM(cs.cs_net_profit) AS cs_total_profit,
        SUM(cs.cs_ext_tax) AS cs_total_tax
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
ws_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        COUNT(*) AS ws_transactions,
        SUM(ws.ws_sales_price) AS ws_total_sales,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        SUM(ws.ws_ext_tax) AS ws_total_tax
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
inv_agg AS (
    SELECT
        inv.inv_date_sk AS date_sk,
        SUM(inv.inv_quantity_on_hand) AS inv_total_quantity
    FROM inventory inv
    GROUP BY inv.inv_date_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk AS date_sk,
        COUNT(*) AS stores_closed,
        SUM(s.s_floor_space) AS total_floor_space
    FROM store s
    GROUP BY s.s_closed_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    ca.cs_transactions,
    ca.cs_total_sales,
    wa.ws_transactions,
    wa.ws_total_sales,
    ia.inv_total_quantity,
    sta.stores_closed,
    (ca.cs_total_sales + wa.ws_total_sales) AS combined_total_sales,
    (ca.cs_total_profit + wa.ws_total_profit) AS combined_total_profit,
    CASE
        WHEN (ca.cs_total_sales + wa.ws_total_sales) > 0 THEN
            (ca.cs_total_profit + wa.ws_total_profit) /
            (ca.cs_total_sales + wa.ws_total_sales)
        ELSE NULL
    END AS overall_profit_margin,
    ROW_NUMBER() OVER (
        PARTITION BY d.d_year
        ORDER BY (ca.cs_total_sales + wa.ws_total_sales) DESC
    ) AS sales_rank
FROM date_dim d
LEFT JOIN cs_agg ca   ON ca.date_sk = d.d_date_sk
LEFT JOIN ws_agg wa   ON wa.date_sk = d.d_date_sk
LEFT JOIN inv_agg ia  ON ia.date_sk = d.d_date_sk
LEFT JOIN store_agg sta ON sta.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
ORDER BY combined_total_sales DESC
LIMIT 100
