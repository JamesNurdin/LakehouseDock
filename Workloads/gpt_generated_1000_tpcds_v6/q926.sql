WITH sales_by_store_hour AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_state AS state,
        td.t_hour AS hour_of_day,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state = 'CA'
      AND s.s_rec_start_date >= DATE '1999-01-01'
      AND td.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY s.s_store_id, s.s_state, td.t_hour
)
SELECT
    store_id,
    state,
    AVG(total_sales) AS avg_hourly_sales,
    SUM(total_profit) AS total_profit,
    COUNT(*) AS hours_with_sales
FROM sales_by_store_hour
WHERE total_sales > (
    SELECT AVG(ss_ext_sales_price)
    FROM store_sales
)
GROUP BY store_id, state
HAVING SUM(total_profit) > 0
ORDER BY avg_hourly_sales DESC
LIMIT 100
