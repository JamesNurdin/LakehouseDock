WITH
    store_union AS (
        SELECT DISTINCT ss_store_sk
        FROM store_sales
        WHERE ss_coupon_amt > 400.00
        UNION
        SELECT DISTINCT ss_store_sk
        FROM store_sales
        WHERE ss_quantity > 5
    ),
    base_agg AS (
        SELECT
            income_band.ib_income_band_sk,
            income_band.ib_lower_bound,
            income_band.ib_upper_bound,
            household_demographics.hd_buy_potential,
            time_dim.t_hour,
            store_sales.ss_store_sk,
            COUNT(*) AS sales_cnt,
            SUM(store_sales.ss_net_profit) AS total_net_profit,
            AVG(store_sales.ss_net_profit) AS avg_net_profit,
            SUM(store_sales.ss_ext_discount_amt) AS total_discount
        FROM store_sales
        JOIN time_dim
            ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
        JOIN household_demographics
            ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
        LEFT JOIN income_band
            ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
        WHERE income_band.ib_lower_bound >= 140001
          AND income_band.ib_upper_bound <= 170000
          AND household_demographics.hd_vehicle_count > 1
          AND store_sales.ss_ext_discount_amt > 100.0
          AND time_dim.t_hour BETWEEN 8 AND 12
          AND store_sales.ss_store_sk IN (SELECT ss_store_sk FROM store_union)
        GROUP BY
            income_band.ib_income_band_sk,
            income_band.ib_lower_bound,
            income_band.ib_upper_bound,
            household_demographics.hd_buy_potential,
            time_dim.t_hour,
            store_sales.ss_store_sk
    )
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    AVG(total_net_profit) AS avg_total_net_profit,
    SUM(sales_cnt) AS total_sales_cnt
FROM base_agg
WHERE avg_net_profit > (SELECT AVG(total_net_profit) FROM base_agg)
GROUP BY
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential
HAVING SUM(sales_cnt) > 10
ORDER BY avg_total_net_profit DESC
LIMIT 100
