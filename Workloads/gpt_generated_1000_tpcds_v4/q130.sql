WITH sales_returns AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_refunded_cash,
        ss.ss_ext_tax,
        sr.sr_return_time_sk,
        ss.ss_wholesale_cost
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count BETWEEN 2 AND 6
      AND ss.ss_wholesale_cost >= 30
      AND ss.ss_ext_tax > 10
      AND sr.sr_return_time_sk BETWEEN 34000 AND 42000
)
SELECT
    hd_demo_sk,
    hd_vehicle_count,
    hd_dep_count,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_refunded_cash) AS total_refunded,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_net_profit) - SUM(sr_refunded_cash) AS profit_after_returns,
    CASE
        WHEN SUM(ss_net_profit) - SUM(sr_refunded_cash) > 5000 THEN 'HIGH'
        WHEN SUM(ss_net_profit) - SUM(sr_refunded_cash) > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY SUM(ss_net_profit) - SUM(sr_refunded_cash) DESC) AS profit_rank
FROM sales_returns
GROUP BY
    hd_demo_sk,
    hd_vehicle_count,
    hd_dep_count,
    ib_lower_bound,
    ib_upper_bound
ORDER BY profit_rank
LIMIT 100
