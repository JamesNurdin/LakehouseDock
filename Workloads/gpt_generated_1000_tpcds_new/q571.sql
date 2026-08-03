WITH
  cs_agg AS (
    SELECT
      cs_sold_time_sk,
      cs_item_sk,
      cs_warehouse_sk,
      cs_ship_mode_sk,
      cs_bill_cdemo_sk,
      cs_bill_hdemo_sk,
      cs_bill_addr_sk,
      cs_ship_cdemo_sk,
      cs_ship_hdemo_sk,
      cs_ship_addr_sk,
      SUM(cs_net_paid) AS total_sales,
      SUM(cs_quantity) AS total_qty
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_net_paid > 0
      AND cs_sold_time_sk BETWEEN 1000 AND 2000
      AND cs_warehouse_sk IS NOT NULL
      AND cs_item_sk IS NOT NULL
      AND cs_ship_mode_sk IS NOT NULL
    GROUP BY
      cs_sold_time_sk, cs_item_sk, cs_warehouse_sk, cs_ship_mode_sk,
      cs_bill_cdemo_sk, cs_bill_hdemo_sk, cs_bill_addr_sk,
      cs_ship_cdemo_sk, cs_ship_hdemo_sk, cs_ship_addr_sk
  ),
  sr_agg AS (
    SELECT
      sr_return_time_sk,
      sr_item_sk,
      sr_cdemo_sk,
      sr_hdemo_sk,
      sr_addr_sk,
      sr_reason_sk,
      SUM(sr_return_amt) AS total_returns,
      SUM(sr_return_quantity) AS total_return_qty
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_return_time_sk BETWEEN 1000 AND 2000
      AND sr_item_sk IS NOT NULL
    GROUP BY
      sr_return_time_sk, sr_item_sk, sr_cdemo_sk,
      sr_hdemo_sk, sr_addr_sk, sr_reason_sk
  ),
  base AS (
    SELECT
      COALESCE(ca.cs_sold_time_sk, ra.sr_return_time_sk) AS time_sk,
      COALESCE(ca.cs_item_sk, ra.sr_item_sk)           AS item_sk,
      ca.total_sales,
      ra.total_returns,
      i.i_category,
      w.w_warehouse_sq_ft,
      sm.sm_type,
      r.r_reason_desc,
      cd_bill.cd_gender AS bill_gender,
      hd_bill.hd_income_band_sk,
      ib.ib_lower_bound,
      td.t_hour,
      w.w_state,
      ca.cs_ship_mode_sk,
      ca.cs_bill_addr_sk,
      cj.dummy_flag
    FROM cs_agg ca
    FULL OUTER JOIN sr_agg ra
      ON ca.cs_sold_time_sk = ra.sr_return_time_sk
    LEFT JOIN time_dim td
      ON td.t_time_sk = COALESCE(ca.cs_sold_time_sk, ra.sr_return_time_sk)
    LEFT JOIN item i
      ON i.i_item_sk = COALESCE(ca.cs_item_sk, ra.sr_item_sk)
    LEFT JOIN warehouse w
      ON w.w_warehouse_sk = ca.cs_warehouse_sk
    LEFT JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = ca.cs_ship_mode_sk
    LEFT JOIN customer_address ca_bill_addr
      ON ca_bill_addr.ca_address_sk = ca.cs_bill_addr_sk
    LEFT JOIN customer_address ca_ship_addr
      ON ca_ship_addr.ca_address_sk = ca.cs_ship_addr_sk
    LEFT JOIN customer_address ca_ret_addr
      ON ca_ret_addr.ca_address_sk = ra.sr_addr_sk
    LEFT JOIN customer_demographics cd_bill
      ON cd_bill.cd_demo_sk = ca.cs_bill_cdemo_sk
    LEFT JOIN customer_demographics cd_ship
      ON cd_ship.cd_demo_sk = ca.cs_ship_cdemo_sk
    LEFT JOIN customer_demographics cd_ret
      ON cd_ret.cd_demo_sk = ra.sr_cdemo_sk
    LEFT JOIN household_demographics hd_bill
      ON hd_bill.hd_demo_sk = ca.cs_bill_hdemo_sk
    LEFT JOIN household_demographics hd_ship
      ON hd_ship.hd_demo_sk = ca.cs_ship_hdemo_sk
    LEFT JOIN household_demographics hd_ret
      ON hd_ret.hd_demo_sk = ra.sr_hdemo_sk
    LEFT JOIN income_band ib
      ON ib.ib_income_band_sk = hd_bill.hd_income_band_sk
    LEFT JOIN reason r
      ON r.r_reason_sk = ra.sr_reason_sk
    CROSS JOIN (SELECT 1 AS dummy_flag) AS cj
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_category = 'Sports'
      AND w.w_warehouse_sq_ft > 500000
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%missing%'
  ),
  agg1 AS (
    SELECT
      time_sk,
      item_sk,
      SUM(total_sales) AS sum_sales,
      SUM(total_returns) AS sum_returns,
      w_state,
      dummy_flag
    FROM base
    GROUP BY time_sk, item_sk, w_state, dummy_flag
    HAVING SUM(total_sales) > 5000
  ),
  agg2 AS (
    SELECT
      time_sk,
      item_sk,
      SUM(total_sales) * 0.8 AS sum_sales,
      SUM(total_returns) * 0.9 AS sum_returns,
      w_state,
      dummy_flag
    FROM base
    WHERE w_state = 'CA'
    GROUP BY time_sk, item_sk, w_state, dummy_flag
  ),
  excl AS (
    SELECT
      time_sk,
      item_sk,
      SUM(total_sales) AS sum_sales,
      SUM(total_returns) AS sum_returns,
      dummy_flag
    FROM base
    GROUP BY time_sk, item_sk, dummy_flag
    HAVING SUM(total_returns) = 0
  )
SELECT time_sk, item_sk, sum_sales, sum_returns
FROM (
  SELECT time_sk, item_sk, sum_sales, sum_returns, dummy_flag FROM agg1
  UNION DISTINCT
  SELECT time_sk, item_sk, sum_sales, sum_returns, dummy_flag FROM agg2
) u
EXCEPT
SELECT time_sk, item_sk, sum_sales, sum_returns
FROM excl
ORDER BY sum_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
