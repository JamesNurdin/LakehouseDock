WITH store_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
combined AS (
    SELECT i_category, d_year, d_month_seq, net_profit, quantity, 'Store'   AS channel FROM store_sales_agg
    UNION ALL
    SELECT i_category, d_year, d_month_seq, net_profit, quantity, 'Catalog' AS channel FROM catalog_sales_agg
    UNION ALL
    SELECT i_category, d_year, d_month_seq, net_profit, quantity, 'Web'     AS channel FROM web_sales_agg
)
SELECT
    i_category,
    d_year,
    d_month_seq,
    channel,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity)   AS total_quantity,
    SUM(net_profit) / NULLIF(SUM(quantity), 0) AS avg_profit_per_unit
FROM combined
GROUP BY i_category, d_year, d_month_seq, channel
ORDER BY i_category, d_year, d_month_seq, channel
