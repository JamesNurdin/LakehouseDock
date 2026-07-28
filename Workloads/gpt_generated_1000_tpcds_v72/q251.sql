WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_category = 'Sports'                         -- predicate 1
      AND s.s_state = 'WA'                                 -- predicate 2
      AND ss.ss_ext_discount_amt > 500                     -- predicate 3
      AND ss.ss_quantity >= 2                              -- predicate 4
      AND cd.cd_gender = 'M'                               -- predicate 5
      AND hd.hd_buy_potential = '501-1000'                 -- predicate 6
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_category
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    c_customer_id,
    c_first_name,
    c_last_name,
    i_category,
    total_sales,
    total_profit,
    total_quantity,
    transaction_count,
    CASE
        WHEN total_discount > 2000 THEN 'Very High Discount'
        WHEN total_discount > 1000 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_level,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY s_store_id, sales_rank
LIMIT 100
