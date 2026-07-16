WITH store_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    category,
    sales_year,
    month_seq,
    SUM(net_profit) AS total_net_profit
FROM (
    SELECT category, sales_year, month_seq, net_profit FROM store_sales_agg
    UNION ALL
    SELECT category, sales_year, month_seq, net_profit FROM web_sales_agg
    UNION ALL
    SELECT category, sales_year, month_seq, net_profit FROM catalog_sales_agg
) combined
GROUP BY category, sales_year, month_seq
ORDER BY total_net_profit DESC
LIMIT 10
