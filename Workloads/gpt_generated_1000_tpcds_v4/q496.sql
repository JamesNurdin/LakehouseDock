WITH
    store_sales_agg AS (
        SELECT
            s.s_store_id   AS store_id,
            d.d_year       AS year,
            SUM(ss.ss_net_profit) AS total_profit
        FROM
            store_sales ss
            JOIN store s ON ss.ss_store_sk = s.s_store_sk
            JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE
            s.s_state = 'CA'
            AND d.d_year >= 2000
        GROUP BY
            s.s_store_id,
            d.d_year
    ),
    catalog_sales_agg AS (
        SELECT
            cp.cp_catalog_page_id AS catalog_page_id,
            d.d_year             AS year,
            SUM(cs.cs_net_profit) AS total_profit
        FROM
            catalog_sales cs
            JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
            JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE
            cp.cp_type = 'electronics'
            AND d.d_year >= 2000
        GROUP BY
            cp.cp_catalog_page_id,
            d.d_year
    ),
    combined AS (
        SELECT
            'store'   AS source,
            store_id  AS id,
            year,
            total_profit
        FROM
            store_sales_agg
        UNION ALL
        SELECT
            'catalog' AS source,
            catalog_page_id AS id,
            year,
            total_profit
        FROM
            catalog_sales_agg
    )
SELECT
    source,
    year,
    SUM(total_profit) AS year_total_profit
FROM
    combined
GROUP BY
    source,
    year
HAVING
    SUM(total_profit) > 10000
ORDER BY
    year_total_profit DESC
LIMIT 100
