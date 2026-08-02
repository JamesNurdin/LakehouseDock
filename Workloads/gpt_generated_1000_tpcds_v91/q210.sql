WITH valid_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_class_id IN (1, 3, 5)
    EXCEPT
    SELECT ss_item_sk AS i_item_sk
    FROM store_sales
    WHERE ss_quantity = 0
),

sales_data AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        ss.ss_ext_discount_amt,
        c.c_first_name,
        c.c_last_name,
        i.i_product_name,
        i.i_class,
        i.i_manufact_id,
        t.t_hour,
        t.t_minute
    FROM store_sales ss
    INNER JOIN valid_items vi ON ss.ss_item_sk = vi.i_item_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE
        ss.ss_quantity > 0
        AND ss.ss_ext_tax > 5
        AND i.i_manufact_id NOT IN (995, 214)
        AND c.c_preferred_cust_flag = 'Y'
        AND t.t_hour BETWEEN 8 AND 18
),

ranked_sales AS (
    SELECT
        sd.ss_customer_sk,
        sd.c_first_name,
        sd.c_last_name,
        sd.i_class,
        SUM(sd.ss_net_paid) AS total_net_paid,
        SUM(sd.ss_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY sd.i_class ORDER BY SUM(sd.ss_net_paid) DESC) AS class_rank
    FROM sales_data sd
    GROUP BY
        sd.ss_customer_sk,
        sd.c_first_name,
        sd.c_last_name,
        sd.i_class
),

filtered_ranked AS (
    SELECT *
    FROM ranked_sales
    WHERE class_rank <= 10
      AND NOT EXISTS (
          SELECT 1
          FROM store_sales ss2
          INNER JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
          WHERE ss2.ss_customer_sk = ranked_sales.ss_customer_sk
            AND i2.i_manufact_id IN (625, 479)
      )
),

top_customers AS (
    SELECT
        ss_customer_sk,
        c_first_name,
        c_last_name,
        i_class,
        total_net_paid,
        class_rank,
        CASE
            WHEN total_net_paid > 2000 THEN 'Platinum'
            WHEN total_net_paid > 1000 THEN 'Gold'
            ELSE 'Silver'
        END AS tier
    FROM filtered_ranked
    WHERE total_net_paid > 500
),

mid_customers AS (
    SELECT
        ss_customer_sk,
        c_first_name,
        c_last_name,
        i_class,
        total_net_paid,
        class_rank,
        CASE
            WHEN total_net_paid > 1500 THEN 'Gold'
            WHEN total_net_paid > 800 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier
    FROM filtered_ranked
    WHERE total_net_paid BETWEEN 200 AND 500
),

combined AS (
    SELECT * FROM top_customers
    UNION ALL
    SELECT * FROM mid_customers
)

SELECT
    ss_customer_sk,
    c_first_name,
    c_last_name,
    i_class,
    total_net_paid,
    class_rank,
    tier
FROM combined
ORDER BY total_net_paid DESC, class_rank
LIMIT 100
