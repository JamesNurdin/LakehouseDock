WITH wr_agg AS (
    SELECT
        wr_refunded_cdemo_sk AS cd_demo_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_fee) AS total_return_fee,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_fee < 20.00
      AND wr_returning_hdemo_sk IN (5919, 2368)
    GROUP BY wr_refunded_cdemo_sk
)
SELECT
    cd.cd_gender,
    cd.cd_education_status,
    ss.ss_store_sk,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    AVG(ss.ss_ext_tax) AS avg_tax,
    MIN(ss.ss_ext_tax) AS min_tax,
    MAX(ss.ss_ext_tax) AS max_tax,
    COALESCE(wr.total_return_amt, 0) AS total_return_amount,
    COALESCE(wr.total_return_fee, 0) AS total_return_fee,
    COALESCE(wr.return_cnt, 0) AS return_cnt
FROM store_sales ss
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN wr_agg wr
  ON cd.cd_demo_sk = wr.cd_demo_sk
WHERE ss.ss_ext_tax > 20.00
  AND ss.ss_net_paid_inc_tax BETWEEN 1000 AND 5000
  AND ss.ss_quantity >= 2
  AND ss.ss_store_sk = 10
  AND cd.cd_gender = 'M'
  AND cd.cd_dep_count <= 3
  AND cd.cd_purchase_estimate >= 5000
GROUP BY
    cd.cd_gender,
    cd.cd_education_status,
    ss.ss_store_sk,
    wr.total_return_amt,
    wr.total_return_fee,
    wr.return_cnt
ORDER BY total_sales DESC
LIMIT 100
