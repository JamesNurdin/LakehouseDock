WITH
    store_agg AS (
        SELECT
            d.d_date AS sale_date,
            SUM(ss.ss_net_paid) AS net_paid,
            SUM(ss.ss_net_profit) AS net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date
    ),
    web_agg AS (
        SELECT
            d.d_date AS sale_date,
            SUM(ws.ws_net_paid) AS net_paid,
            SUM(ws.ws_net_profit) AS net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date
    ),
    store_web_full AS (
        SELECT
            COALESCE(s.sale_date, w.sale_date) AS sale_date,
            COALESCE(s.net_paid, 0) + COALESCE(w.net_paid, 0) AS net_paid,
            COALESCE(s.net_profit, 0) + COALESCE(w.net_profit, 0) AS net_profit,
            'store_web' AS source
        FROM store_agg s
        FULL OUTER JOIN web_agg w
            ON s.sale_date = w.sale_date
    ),
    catalog_agg AS (
        SELECT
            d.d_date AS sale_date,
            SUM(cs.cs_net_paid) AS net_paid,
            SUM(cs.cs_net_profit) AS net_profit,
            'catalog' AS source
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date
    ),
    union_all_sales AS (
        SELECT sale_date, source, net_paid, net_profit FROM store_web_full
        UNION ALL
        SELECT sale_date, source, net_paid, net_profit FROM catalog_agg
    )
SELECT
    sale_date,
    source,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit
FROM union_all_sales
GROUP BY ROLLUP (sale_date, source)
ORDER BY sale_date, source
