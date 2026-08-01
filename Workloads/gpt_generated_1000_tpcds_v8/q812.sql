WITH sampled_sales AS (
    SELECT ss_sold_date_sk,
           ss_sold_time_sk,
           ss_item_sk,
           ss_customer_sk,
           ss_cdemo_sk,
           ss_hdemo_sk,
           ss_addr_sk,
           ss_store_sk,
           ss_promo_sk,
           ss_ticket_number,
           ss_quantity,
           ss_wholesale_cost,
           ss_list_price,
           ss_sales_price,
           ss_ext_discount_amt,
           ss_ext_sales_price,
           ss_ext_wholesale_cost,
           ss_ext_list_price,
           ss_ext_tax,
           ss_coupon_amt,
           ss_net_paid,
           ss_net_paid_inc_tax,
           ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sales_price > 20
      AND ss_quantity >= 2
      AND ss_list_price BETWEEN 30 AND 80
      AND ss_ext_tax < 5
      AND ss_net_profit > 0
      AND ss_coupon_amt = 0
),
eligible_keys AS (
    SELECT DISTINCT ss_hdemo_sk AS hd_demo_sk
    FROM sampled_sales
    WHERE ss_sales_price > 30
),
excluded_keys AS (
    SELECT DISTINCT ss_hdemo_sk AS hd_demo_sk
    FROM store_sales
    WHERE ss_sales_price < 15
),
final_keys AS (
    SELECT hd_demo_sk
    FROM eligible_keys
    EXCEPT
    SELECT hd_demo_sk
    FROM excluded_keys
),
joined_data AS (
    SELECT
        ss.ss_hdemo_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        hd.hd_dep_count
    FROM sampled_sales ss
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_hdemo_sk IN (SELECT hd_demo_sk FROM final_keys)
      AND hd.hd_vehicle_count IN (1, 2, 3)
      AND hd.hd_dep_count <= 5
      AND hd.hd_buy_potential = 'HIGH'
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_customer_sk = ss.ss_customer_sk
            AND ss2.ss_quantity > 5
      )
)
SELECT
    hd_buy_potential,
    hd_vehicle_count,
    COUNT(*) AS cnt_transactions,
    SUM(ss_sales_price) AS total_sales_price,
    AVG(ss_net_profit) AS avg_net_profit,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price
FROM joined_data
GROUP BY ROLLUP (hd_buy_potential, hd_vehicle_count)
ORDER BY hd_buy_potential NULLS LAST, hd_vehicle_count NULLS LAST
