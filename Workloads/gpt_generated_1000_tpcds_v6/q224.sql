WITH
  joined_data AS (
    SELECT
      cp.cp_department,
      hd_bill.hd_income_band_sk,
      cs.cs_net_profit,
      cs.cs_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss
    FROM catalog_sales cs
      JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
      JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
      JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
      JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
      JOIN store_returns sr
        ON sr.sr_customer_sk = cust_bill.c_customer_sk
      JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
      JOIN household_demographics hd_current
        ON cust_bill.c_current_hdemo_sk = hd_current.hd_demo_sk
      JOIN customer cust_ship2
        ON sr.sr_customer_sk = cust_ship2.c_customer_sk
    WHERE cp.cp_catalog_page_number BETWEEN 5 AND 20
      AND hd_bill.hd_income_band_sk IN (1, 5, 9, 10)
  ),
  aggregated AS (
    SELECT
      cp_department,
      hd_income_band_sk,
      SUM(cs_net_profit) AS total_profit,
      SUM(cs_quantity) AS total_quantity,
      SUM(sr_return_amt) AS total_return_amt,
      SUM(sr_net_loss) AS total_net_loss
    FROM joined_data
    GROUP BY cp_department, hd_income_band_sk
  )
SELECT
  cp_department,
  hd_income_band_sk,
  total_profit,
  total_quantity,
  total_return_amt,
  total_net_loss,
  SUM(total_profit) OVER (PARTITION BY cp_department ORDER BY hd_income_band_sk) AS cumulative_profit_by_income,
  RANK() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
