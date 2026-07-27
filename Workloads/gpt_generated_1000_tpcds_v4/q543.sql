WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        'store' AS source,
        SUM(ss.ss_net_paid) AS total_sales,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        d.d_year BETWEEN 2001 AND 2002
    GROUP BY
        d.d_year
    HAVING
        SUM(ss.ss_net_paid) > 1000
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        'catalog' AS source,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_net_profit) > 8000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        cc.cc_class = 'C'
        AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY
        d.d_year
    HAVING
        SUM(cs.cs_ext_sales_price) > 500
)
SELECT * FROM store_sales_agg
UNION ALL
SELECT * FROM catalog_sales_agg
ORDER BY year, source
LIMIT 100
