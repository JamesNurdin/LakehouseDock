WITH sales_agg AS (
    SELECT
        p.p_promo_name AS p_promo_name,
        td.t_meal_time AS t_meal_time,
        c_bill.c_preferred_cust_flag AS c_preferred_cust_flag,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_sales_price) AS avg_sales,
        COUNT(*) AS order_cnt,
        MIN(cs.cs_ext_discount_amt) AS min_discount,
        MAX(cs.cs_ext_discount_amt) AS max_discount
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    WHERE cs.cs_ext_wholesale_cost > 3000.00
      AND cs.cs_ext_ship_cost < 500.00
      AND cs.cs_quantity >= 2
      AND td.t_am_pm = 'PM'
      AND td.t_meal_time = 'dinner'
      AND c_bill.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM customer c_ship
          WHERE c_ship.c_customer_sk = cs.cs_ship_customer_sk
            AND c_ship.c_birth_day = 30
            AND c_ship.c_birth_month = 12
      )
    GROUP BY p.p_promo_name, td.t_meal_time, c_bill.c_preferred_cust_flag
)
SELECT
    p_promo_name,
    t_meal_time,
    c_preferred_cust_flag,
    total_sales,
    avg_sales,
    order_cnt,
    min_discount,
    max_discount,
    RANK() OVER (PARTITION BY p_promo_name ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
