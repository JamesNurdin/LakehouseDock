WITH sales_agg AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost
  FROM catalog_sales cs
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE
    cs.cs_ext_wholesale_cost > 1000.00
    AND cs.cs_quantity BETWEEN 1 AND 100
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
    AND cs.cs_list_price < 5000.00
    AND cs.cs_net_paid_inc_tax > 0
    AND EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_return_amt > 50.00
        AND wr.wr_return_quantity <= 50
        AND wr.wr_returned_time_sk BETWEEN 20000 AND 50000
    )
  GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
)
SELECT
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  total_net_profit,
  sales_cnt,
  avg_quantity,
  total_ship_cost,
  total_net_profit / sales_cnt AS avg_profit_per_sale
FROM sales_agg
WHERE
  total_net_profit > 100000.00
  AND sales_cnt >= 10
  AND avg_quantity > 10
  AND total_ship_cost > 5000.00
ORDER BY
  avg_profit_per_sale DESC,
  sales_cnt DESC
LIMIT 100
