WITH sales_by_income_vehicle AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND hd.hd_dep_count <= 2
      AND ib.ib_lower_bound >= 10001
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_vehicle_count
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT 
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_vehicle_count,
    total_sales,
    total_discount,
    avg_profit,
    distinct_tickets,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_by_income_vehicle
ORDER BY sales_rank
LIMIT 5
