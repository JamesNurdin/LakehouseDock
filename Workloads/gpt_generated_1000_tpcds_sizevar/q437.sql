WITH catalog_agg AS (
    SELECT
        c.c_customer_id AS c_customer_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id
    HAVING SUM(cs.cs_ext_sales_price) > (
        SELECT AVG(sub.total_sales) FROM (
            SELECT SUM(cs2.cs_ext_sales_price) AS total_sales
            FROM catalog_sales cs2
            JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2022
            GROUP BY cs2.cs_bill_customer_sk
        ) sub
    )
),
store_agg AS (
    SELECT
        c.c_customer_id AS c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id
    HAVING SUM(ss.ss_ext_sales_price) > (
        SELECT AVG(sub.total_sales) FROM (
            SELECT SUM(ss2.ss_ext_sales_price) AS total_sales
            FROM store_sales ss2
            JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2022
            GROUP BY ss2.ss_customer_sk
        ) sub
    )
)
SELECT *
FROM (
    (SELECT c_customer_id, total_sales, profit_category FROM catalog_agg)
    INTERSECT
    (SELECT c_customer_id, total_sales, profit_category FROM store_agg)
) AS intersect_result
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
