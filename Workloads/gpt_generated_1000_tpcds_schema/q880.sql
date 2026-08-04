WITH ss_store AS (
    SELECT
        s.s_store_name AS entity,
        CAST(td.t_time AS VARCHAR) AS attr,
        td.t_time_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_time IS NOT NULL
    GROUP BY s.s_store_name, td.t_time, td.t_time_sk
),
first_part AS (
    SELECT
        entity,
        attr,
        CASE WHEN total_sales > 1000 THEN 'High' ELSE 'Low' END AS category,
        total_sales AS metric1,
        (SELECT SUM(cs.cs_ext_ship_cost)
         FROM catalog_sales cs
         WHERE cs.cs_sold_time_sk = ss_store.t_time_sk) AS metric2
    FROM ss_store
),
second_part AS (
    SELECT
        c.c_customer_id AS entity,
        hd.hd_buy_potential AS attr,
        CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'Big' ELSE 'Small' END AS category,
        SUM(cr.cr_return_amount) AS metric1,
        CAST((SELECT COUNT(*)
               FROM catalog_sales cs
               WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS DECIMAL(15,2)) AS metric2
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_id, hd.hd_buy_potential, c.c_customer_sk
)
SELECT *
FROM first_part
UNION
SELECT *
FROM second_part
ORDER BY entity ASC
LIMIT 100
