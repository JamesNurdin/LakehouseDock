WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_sales_price) AS avg_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 1
      AND ss_wholesale_cost > 5
    GROUP BY ss_customer_sk, ss_sold_time_sk
),

eligible_customers AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    EXCEPT
    SELECT c_customer_sk
    FROM customer
    WHERE c_birth_year < 1980
),

cust_details AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM eligible_customers)
      AND ca.ca_city IN ('Union', 'Pleasant Valley', 'Oakland')
      AND hd.hd_buy_potential = '>10000'
      AND hd.hd_dep_count >= 2
),

time_lunch AS (
    SELECT t_time_sk, t_hour, t_second, t_meal_time
    FROM time_dim
    WHERE t_meal_time = 'Lunch'
      AND t_second BETWEEN 0 AND 20
      AND t_hour BETWEEN 11 AND 14
),

time_breakfast AS (
    SELECT t_time_sk, t_hour, t_second, t_meal_time
    FROM time_dim
    WHERE t_meal_time = 'Breakfast'
      AND t_second BETWEEN 0 AND 20
      AND t_hour BETWEEN 6 AND 9
)

SELECT
    ca_city,
    hd_buy_potential,
    SUM(total_sales) AS sum_total_sales,
    AVG(avg_sales) AS avg_of_avg_sales,
    COUNT(*) AS cnt_rows,
    MIN(total_sales) AS min_total_sales,
    MAX(total_sales) AS max_total_sales,
    GROUPING(ca_city) AS grp_city,
    GROUPING(hd_buy_potential) AS grp_potential
FROM (
    SELECT
        cd.ca_city,
        cd.hd_buy_potential,
        sa.total_sales,
        sa.avg_sales
    FROM ss_agg sa
    JOIN cust_details cd ON sa.ss_customer_sk = cd.c_customer_sk
    JOIN time_lunch tl ON sa.ss_sold_time_sk = tl.t_time_sk
    UNION DISTINCT
    SELECT
        cd.ca_city,
        cd.hd_buy_potential,
        sa.total_sales,
        sa.avg_sales
    FROM ss_agg sa
    JOIN cust_details cd ON sa.ss_customer_sk = cd.c_customer_sk
    JOIN time_breakfast tb ON sa.ss_sold_time_sk = tb.t_time_sk
) u
GROUP BY ROLLUP (ca_city, hd_buy_potential)
HAVING SUM(total_sales) > 500
ORDER BY ca_city, hd_buy_potential
LIMIT 100
