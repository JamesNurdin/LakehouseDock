WITH
    sales_filtered AS (
        SELECT
            cs_order_number,
            cs_bill_cdemo_sk,
            cs_ship_cdemo_sk,
            cs_ext_list_price,
            cs_wholesale_cost,
            cs_ext_tax,
            cs_net_profit,
            cs_ship_mode_sk
        FROM catalog_sales
        WHERE cs_ext_list_price > 5000
          AND cs_wholesale_cost < 50
          AND cs_ext_tax BETWEEN 20 AND 100
    ),
    demographics_filtered AS (
        SELECT
            cd_demo_sk,
            cd_gender,
            cd_credit_rating,
            cd_dep_count
        FROM customer_demographics
        WHERE cd_dep_count >= 3
          AND cd_credit_rating = 'Good'
    ),
    high_profit_orders AS (
        SELECT cs_order_number
        FROM sales_filtered
        WHERE cs_net_profit > 1000
    ),
    low_profit_orders AS (
        SELECT cs_order_number
        FROM sales_filtered
        WHERE cs_net_profit < 200
    ),
    target_orders AS (
        SELECT cs_order_number
        FROM high_profit_orders
        EXCEPT
        SELECT cs_order_number
        FROM low_profit_orders
    ),
    joined_data AS (
        SELECT
            s.cs_order_number,
            d.cd_gender,
            d.cd_credit_rating,
            s.cs_ship_mode_sk,
            s.cs_ext_list_price,
            s.cs_net_profit,
            CASE
                WHEN s.cs_net_profit > 2000 THEN 'High'
                WHEN s.cs_net_profit BETWEEN 500 AND 2000 THEN 'Medium'
                ELSE 'Low'
            END AS profit_category
        FROM sales_filtered s
        JOIN demographics_filtered d
          ON s.cs_bill_cdemo_sk = d.cd_demo_sk
        JOIN target_orders t
          ON s.cs_order_number = t.cs_order_number
    )
SELECT
    cd_gender,
    cd_credit_rating,
    cs_ship_mode_sk,
    profit_category,
    COUNT(*) AS order_cnt,
    SUM(cs_ext_list_price) AS total_list_price,
    AVG(cs_net_profit) AS avg_net_profit,
    MIN(cs_net_profit) AS min_net_profit,
    MAX(cs_net_profit) AS max_net_profit
FROM joined_data
GROUP BY CUBE (cd_gender, cd_credit_rating, cs_ship_mode_sk, profit_category)
ORDER BY order_cnt DESC, total_list_price DESC
LIMIT 100
