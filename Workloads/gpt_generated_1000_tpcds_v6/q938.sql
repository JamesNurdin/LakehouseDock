WITH sales_returns AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_quantity > 1
      AND cs.cs_wholesale_cost > 5
      AND hd.hd_dep_count >= 2
      AND hd.hd_buy_potential <> 'Unknown'
      AND sr.sr_return_quantity > 0
    GROUP BY cs.cs_bill_hdemo_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(s.total_sales) AS sum_sales,
    AVG(s.total_profit) AS avg_profit,
    SUM(s.total_return_amt) AS sum_returns,
    COUNT(*) AS num_demographics
FROM sales_returns s
JOIN household_demographics hd
    ON s.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound <= 200000
  AND ib.ib_lower_bound >= 20000
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(s.total_sales) > 10000
ORDER BY sum_sales DESC
LIMIT 100
