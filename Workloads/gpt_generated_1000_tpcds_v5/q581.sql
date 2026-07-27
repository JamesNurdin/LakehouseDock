WITH base AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    ib.ib_income_band_sk AS income_band_sk,
    ib.ib_lower_bound AS lower_bound,
    ib.ib_upper_bound AS upper_bound,
    hd.hd_buy_potential AS buy_potential,
    SUM(cr.cr_return_amount) AS sum_return_amount,
    SUM(cr.cr_fee) AS sum_fee,
    SUM(ss.ss_ext_sales_price) AS sum_sales,
    SUM(ss.ss_net_profit) AS sum_profit,
    SUM(wr.wr_return_amt) AS sum_web_return_amt,
    COUNT(*) AS txn_count
  FROM catalog_returns cr
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN web_returns wr
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cr.cr_return_amount > 100
    AND cr.cr_fee BETWEEN 5 AND 70
    AND ss.ss_ext_sales_price > 500
    AND ib.ib_lower_bound >= 30000
    AND w.w_warehouse_sq_ft > 10000
  GROUP BY w.w_warehouse_name, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
),
final AS (
  SELECT
    warehouse_name,
    income_band_sk,
    lower_bound,
    upper_bound,
    buy_potential,
    sum_return_amount,
    sum_fee,
    sum_sales,
    sum_profit,
    sum_web_return_amt,
    txn_count,
    sum_sales / NULLIF(txn_count, 0) AS avg_sales_per_txn,
    RANK() OVER (PARTITION BY warehouse_name ORDER BY sum_sales DESC) AS sales_rank,
    SUM(sum_sales) OVER (PARTITION BY warehouse_name ORDER BY income_band_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_by_income
  FROM base
)
SELECT
  warehouse_name,
  income_band_sk,
  lower_bound,
  upper_bound,
  buy_potential,
  sum_return_amount,
  sum_fee,
  sum_sales,
  sum_profit,
  sum_web_return_amt,
  txn_count,
  avg_sales_per_txn,
  sales_rank,
  cum_sales_by_income
FROM final
WHERE avg_sales_per_txn > 200
  AND sum_profit > 0
  AND sales_rank <= 5
ORDER BY warehouse_name ASC, sum_sales DESC
LIMIT 100
