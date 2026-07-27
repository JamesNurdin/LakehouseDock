WITH sales_join AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_store_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_sales_price,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM store_sales ss
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
  WHERE ss.ss_quantity > 1
    AND ss.ss_sales_price BETWEEN 100 AND 5000
    AND i.i_current_price > 10
    AND cd.cd_gender = 'M'
    AND hd.hd_vehicle_count >= 2
    AND ib.ib_lower_bound >= 150000
)
SELECT
  sj.i_item_id,
  sj.i_product_name,
  sj.ss_store_sk,
  sj.ss_sold_date_sk,
  sj.ss_quantity,
  sj.ss_sales_price,
  sj.ss_net_profit,
  SUM(sj.ss_ext_sales_price) OVER (
    PARTITION BY sj.i_item_id
    ORDER BY sj.ss_sold_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales,
  RANK() OVER (
    PARTITION BY sj.ss_store_sk
    ORDER BY sj.ss_net_profit DESC
  ) AS profit_rank_store,
  CASE
    WHEN sj.ss_net_profit > 1000 THEN 'High'
    WHEN sj.ss_net_profit > 0 THEN 'Medium'
    ELSE 'Low'
  END AS profit_category
FROM sales_join sj
ORDER BY sj.ss_net_profit DESC, cumulative_sales DESC
LIMIT 100
