WITH sales_by_brand_demo AS (
    SELECT
        item.i_brand,
        household_demographics.hd_buy_potential,
        SUM(store_sales.ss_ext_sales_price) AS total_sales,
        SUM(store_sales.ss_net_profit) AS total_profit,
        SUM(store_sales.ss_quantity) AS total_quantity,
        AVG(store_sales.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT item.i_item_sk) AS distinct_items_sold
    FROM
        store_sales
        JOIN item ON store_sales.ss_item_sk = item.i_item_sk
        JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    WHERE
        household_demographics.hd_vehicle_count >= 2
    GROUP BY
        item.i_brand,
        household_demographics.hd_buy_potential
)
SELECT
    i_brand,
    hd_buy_potential,
    total_sales,
    total_profit,
    total_quantity,
    avg_discount,
    distinct_items_sold,
    RANK() OVER (PARTITION BY hd_buy_potential ORDER BY total_profit DESC) AS profit_rank_within_buy_potential,
    SUM(total_profit) OVER (PARTITION BY hd_buy_potential) AS profit_sum_by_buy_potential,
    total_profit / SUM(total_profit) OVER (PARTITION BY hd_buy_potential) AS profit_share
FROM
    sales_by_brand_demo
ORDER BY
    hd_buy_potential,
    profit_rank_within_buy_potential
