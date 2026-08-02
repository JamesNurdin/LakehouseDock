WITH distinct_sales AS (
    SELECT DISTINCT 
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_tax
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 500
),
orders_without_returns AS (
    SELECT cs_order_number
    FROM distinct_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
sales_with_dims AS (
    SELECT 
        ds.cs_order_number,
        ds.cs_ext_sales_price,
        ds.cs_net_profit,
        ds.cs_net_paid_inc_tax,
        ds.cs_sold_date_sk,
        ds.cs_ship_date_sk,
        ds.cs_ship_mode_sk,
        ds.cs_bill_customer_sk,
        ds.cs_bill_cdemo_sk,
        ds.cs_ship_customer_sk,
        ds.cs_ship_cdemo_sk,
        ds.cs_sold_time_sk,
        c_bill.c_birth_country,
        cd_bill.cd_gender,
        sm.sm_type,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        t_sold.t_hour
    FROM distinct_sales ds
    INNER JOIN orders_without_returns owr
        ON ds.cs_order_number = owr.cs_order_number
    INNER JOIN customer c_bill
        ON ds.cs_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer_demographics cd_bill
        ON ds.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer c_ship
        ON ds.cs_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN customer_demographics cd_ship
        ON ds.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN ship_mode sm
        ON ds.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN date_dim d_sold
        ON ds.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON ds.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN time_dim t_sold
        ON ds.cs_sold_time_sk = t_sold.t_time_sk
),
aggregated_sales AS (
    SELECT 
        swd.sold_year,
        swd.sm_type,
        swd.c_birth_country,
        CASE 
            WHEN SUM(swd.cs_net_profit) > 10000 THEN 'High Profit'
            ELSE 'Low/Medium Profit'
        END AS profit_category,
        COUNT(DISTINCT swd.cs_order_number) AS distinct_orders,
        SUM(swd.cs_ext_sales_price) AS total_sales,
        SUM(swd.cs_net_paid_inc_tax) AS total_paid_inc_tax
    FROM sales_with_dims swd
    GROUP BY swd.sold_year, swd.sm_type, swd.c_birth_country
    HAVING SUM(swd.cs_ext_sales_price) > 5000
)
SELECT 
    a.sold_year,
    a.sm_type,
    a.c_birth_country,
    a.profit_category,
    a.distinct_orders,
    a.total_sales,
    a.total_paid_inc_tax,
    ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated_sales a
ORDER BY a.total_sales DESC
LIMIT 100
