WITH filtered_sales AS (
  SELECT
    cs.cs_item_sk AS cs_item_sk,
    i.i_item_id AS i_item_id,
    cs.cs_sold_date_sk AS cs_sold_date_sk,
    cs.cs_net_profit AS cs_net_profit,
    cs.cs_quantity AS cs_quantity,
    cs.cs_ext_sales_price AS cs_ext_sales_price,
    CASE WHEN cs.cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_lower_bound >= 50000
    AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
)
SELECT
  fs.cs_item_sk,
  fs.i_item_id,
  fs.cs_sold_date_sk,
  fs.cs_net_profit,
  fs.profit_category,
  RANK() OVER (PARTITION BY fs.cs_item_sk ORDER BY fs.cs_net_profit DESC) AS profit_rank,
  DENSE_RANK() OVER (PARTITION BY fs.cs_item_sk ORDER BY fs.cs_sold_date_sk) AS date_dense_rank,
  ROW_NUMBER() OVER (PARTITION BY fs.cs_item_sk ORDER BY fs.cs_sold_date_sk) AS row_num,
  SUM(fs.cs_net_profit) OVER (PARTITION BY fs.cs_item_sk ORDER BY fs.cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_day_profit,
  AVG(fs.cs_net_profit) OVER (PARTITION BY fs.cs_item_sk ORDER BY fs.cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_day_avg_profit,
  CASE
    WHEN AVG(fs.cs_net_profit) OVER (PARTITION BY fs.cs_item_sk ORDER BY fs.cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) > 1000 THEN 'Strong'
    ELSE 'Weak'
  END AS trend_category
FROM filtered_sales fs
ORDER BY fs.cs_item_sk, fs.cs_sold_date_sk
