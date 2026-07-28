WITH sub_a AS (
    SELECT
        c.c_salutation AS salutation,
        t.t_am_pm AS am_pm,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
      AND c.c_salutation = 'Mr.'
      AND ss.ss_ext_discount_amt > 500
    GROUP BY GROUPING SETS (
        (c.c_salutation, t.t_am_pm),
        (c.c_salutation),
        (t.t_am_pm),
        ()
    )
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
sub_b AS (
    SELECT
        c.c_salutation AS salutation,
        t.t_am_pm AS am_pm,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'AM'
      AND c.c_salutation = 'Ms.'
      AND ss.ss_ext_discount_amt > 1000
    GROUP BY GROUPING SETS (
        (c.c_salutation, t.t_am_pm),
        (c.c_salutation),
        (t.t_am_pm),
        ()
    )
    HAVING SUM(ss.ss_ext_sales_price) > 1000
)
SELECT
    salutation,
    am_pm,
    total_sales,
    total_profit,
    profit_category,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER () AS grand_total
FROM (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
) AS u
ORDER BY profit_category DESC, total_sales DESC
LIMIT 100
