WITH
    store_sales_sample AS (
        SELECT
            ss_ticket_number AS order_number,
            ss_sold_date_sk AS date_sk,
            ss_net_paid AS net_paid
        FROM tpcds.store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    catalog_sales_all AS (
        SELECT
            cs_order_number AS order_number,
            cs_sold_date_sk AS date_sk,
            cs_net_paid AS net_paid
        FROM tpcds.catalog_sales
    ),
    all_orders AS (
        SELECT order_number, date_sk, net_paid FROM store_sales_sample
        UNION
        SELECT order_number, date_sk, net_paid FROM catalog_sales_all
    ),
    returned_orders AS (
        SELECT cr_order_number AS order_number
        FROM tpcds.catalog_returns
    ),
    non_returned_orders AS (
        SELECT o.order_number, o.date_sk, o.net_paid
        FROM all_orders o
        WHERE o.order_number IN (
            SELECT order_number
            FROM (
                SELECT order_number FROM all_orders
                EXCEPT
                SELECT order_number FROM returned_orders
            ) keep
        )
    ),
    agg_sales AS (
        SELECT
            d.d_year,
            d.d_month_seq AS month,
            SUM(o.net_paid) AS total_sales,
            COUNT(DISTINCT o.order_number) AS order_cnt
        FROM non_returned_orders o
        JOIN tpcds.date_dim d
            ON o.date_sk = d.d_date_sk
        GROUP BY ROLLUP (d.d_year, d.d_month_seq)
    )
SELECT
    a.d_year,
    a.month,
    a.total_sales,
    a.order_cnt,
    (SELECT AVG(p_cost) FROM tpcds.promotion WHERE p_purpose = 'Unknown') AS avg_unknown_promo_cost,
    SUM(a.total_sales) OVER (PARTITION BY a.d_year ORDER BY a.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_year
FROM agg_sales a
ORDER BY
    a.d_year ASC NULLS LAST,
    a.month ASC NULLS LAST
