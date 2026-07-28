WITH filtered_sales AS (
    SELECT
        ss.ss_hdemo_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_list_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_list_price BETWEEN 50 AND 130
      AND ss.ss_ext_discount_amt > 50
), filtered_hd AS (
    SELECT
        hd_demo_sk,
        hd_buy_potential,
        hd_dep_count,
        hd_vehicle_count
    FROM household_demographics hd
    WHERE hd_dep_count IN (1, 2, 3)
      AND hd_buy_potential = '1001-5000'
      AND hd_vehicle_count >= 1
), filtered_item AS (
    SELECT
        i_item_sk,
        i_category,
        i_formulation,
        i_size
    FROM item i
    WHERE i_formulation LIKE '%steel%'
      AND i_size = 'medium'
)
SELECT
    hd.hd_buy_potential,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    MIN(ss.ss_net_profit) AS min_profit,
    MAX(ss.ss_net_profit) AS max_profit
FROM filtered_sales ss
JOIN filtered_hd hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN filtered_item i ON ss.ss_item_sk = i.i_item_sk
GROUP BY ROLLUP (hd.hd_buy_potential, i.i_category)
ORDER BY total_sales DESC
LIMIT 100
