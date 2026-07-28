WITH
  sales_agg AS (
    SELECT
      ss.ss_hdemo_sk AS hd_demo_sk,
      SUM(ss.ss_net_paid_inc_tax) AS total_sales,
      AVG(ss.ss_ext_discount_amt) AS avg_discount,
      COUNT(*) AS sales_cnt
    FROM tpcds.store_sales AS ss
    WHERE ss.ss_net_paid_inc_tax > 100
      AND ss.ss_ext_list_price BETWEEN 500 AND 5000
      AND ss.ss_quantity >= 1
    GROUP BY ss.ss_hdemo_sk
  ),
  returns_agg AS (
    SELECT
      wr.wr_refunded_hdemo_sk AS hd_demo_sk,
      SUM(wr.wr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
    FROM tpcds.web_returns AS wr
    WHERE wr.wr_fee > 20
      AND wr.wr_return_quantity >= 1
      AND wr.wr_return_amt_inc_tax > 50
    GROUP BY wr.wr_refunded_hdemo_sk
  )
SELECT
  hd.hd_income_band_sk,
  hd.hd_buy_potential,
  COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
  SUM(sa.total_sales) AS sum_sales,
  AVG(sa.avg_discount) AS avg_discount,
  SUM(ra.total_return_loss) AS sum_return_loss,
  SUM(sa.sales_cnt) AS total_transactions,
  SUM(ra.return_cnt) AS total_returns
FROM tpcds.household_demographics AS hd
JOIN sales_agg AS sa ON hd.hd_demo_sk = sa.hd_demo_sk
JOIN returns_agg AS ra ON hd.hd_demo_sk = ra.hd_demo_sk
WHERE hd.hd_income_band_sk IN (5, 9, 13)
  AND hd.hd_buy_potential = '501-1000'
  AND hd.hd_vehicle_count >= 1
GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
ORDER BY sum_sales DESC
LIMIT 100
