WITH store_data AS (
        SELECT
            d.d_year AS year,
            'store' AS channel,
            SUM(ss.ss_net_paid) AS total_sales
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 1998 AND 2001
          AND EXISTS (
              SELECT 1
              FROM inventory inv TABLESAMPLE BERNOULLI (10)
              WHERE inv.inv_item_sk = ss.ss_item_sk
                AND inv.inv_quantity_on_hand > 0
          )
        GROUP BY d.d_year
    ),
    web_data AS (
        SELECT
            d.d_year AS year,
            'web' AS channel,
            SUM(ws.ws_net_paid) AS total_sales,
            SUM(p.p_cost) AS total_promo_cost
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN LATERAL (
            SELECT p.p_cost
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
        ) p ON TRUE
        WHERE d.d_year BETWEEN 1998 AND 2001
        GROUP BY d.d_year
    ),
    raw_union AS (
        SELECT year, channel, total_sales FROM store_data
        UNION ALL
        SELECT year, channel, total_sales FROM web_data
    ),
    agg_sales AS (
        SELECT
            year,
            channel,
            SUM(total_sales) AS sales_amount
        FROM raw_union
        GROUP BY ROLLUP (year, channel)
    )
SELECT
    year,
    channel,
    sales_amount,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY sales_amount DESC) AS sales_rank,
    (SELECT AVG(sales_amount) FROM agg_sales) AS overall_avg_sales
FROM agg_sales
ORDER BY year ASC NULLS LAST, channel ASC NULLS LAST
OFFSET 0 LIMIT 100
