WITH bill_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        c.c_customer_id,
        t.t_hour,
        t.t_am_pm
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE c.c_current_addr_sk IN (57690, 3212703)
      AND EXISTS (
          SELECT 1
          FROM time_dim td2
          WHERE td2.t_time_sk = cs.cs_sold_time_sk
            AND td2.t_second > 10
      )
),
ship_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        c.c_customer_id,
        t.t_hour,
        t.t_am_pm
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
      AND cs.cs_ext_sales_price > (
          SELECT avg(cs2.cs_ext_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
      )
)
SELECT cs_sold_date_sk,
       cs_order_number,
       cs_ext_sales_price,
       c_customer_id,
       t_hour,
       t_am_pm
FROM bill_sales
UNION ALL
SELECT cs_sold_date_sk,
       cs_order_number,
       cs_ext_sales_price,
       c_customer_id,
       t_hour,
       t_am_pm
FROM ship_sales
ORDER BY cs_sold_date_sk DESC, cs_order_number
LIMIT 100
