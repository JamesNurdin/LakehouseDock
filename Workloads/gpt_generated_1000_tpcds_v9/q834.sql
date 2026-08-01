WITH base_agg AS (
    SELECT
        store.s_store_id,
        store.s_state,
        store.s_number_employees,
        store.s_floor_space,
        income_band.ib_income_band_sk,
        income_band.ib_lower_bound,
        income_band.ib_upper_bound,
        CASE
            WHEN store.s_floor_space >= 200000 THEN 'Large'
            WHEN store.s_floor_space >= 100000 THEN 'Medium'
            ELSE 'Small'
        END AS store_size,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS num_sales_txns,
        SUM(store_sales.ss_net_paid) AS total_sales_net_paid,
        SUM(store_sales.ss_net_profit) AS total_sales_net_profit,
        SUM(store_returns.sr_return_amt) AS total_return_amount,
        SUM(store_returns.sr_fee) AS total_return_fee,
        COUNT(DISTINCT store_returns.sr_ticket_number) AS num_return_txns
    FROM store
    JOIN store_sales
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN household_demographics
        ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN income_band
        ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    JOIN store_returns
        ON store_returns.sr_ticket_number = store_sales.ss_ticket_number
           AND store_returns.sr_item_sk = store_sales.ss_item_sk
    JOIN reason
        ON store_returns.sr_reason_sk = reason.r_reason_sk
    WHERE store.s_state = 'CA'                                 -- filter 1
      AND income_band.ib_upper_bound >= 100000                 -- filter 2
      AND store_returns.sr_fee > 10                            -- filter 3
      AND store.s_rec_start_date >= DATE '2000-01-01'          -- filter 4
    GROUP BY
        store.s_store_id,
        store.s_state,
        store.s_number_employees,
        store.s_floor_space,
        income_band.ib_income_band_sk,
        income_band.ib_lower_bound,
        income_band.ib_upper_bound,
        CASE
            WHEN store.s_floor_space >= 200000 THEN 'Large'
            WHEN store.s_floor_space >= 100000 THEN 'Medium'
            ELSE 'Small'
        END
)

SELECT
    store_size,
    COUNT(*) AS num_stores,
    AVG(total_sales_net_profit - total_return_amount - total_return_fee) AS avg_net_impact,
    SUM(total_sales_net_paid) / NULLIF(SUM(s_number_employees), 0) AS sales_per_employee
FROM base_agg
GROUP BY store_size
HAVING AVG(total_sales_net_profit - total_return_amount - total_return_fee) > 0
ORDER BY avg_net_impact DESC
LIMIT 100
