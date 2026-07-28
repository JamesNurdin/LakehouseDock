WITH agg_sales AS (
    SELECT
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_net_profit)        AS total_net_profit,
        SUM(ss_ext_sales_price)   AS total_sales,
        COUNT(*)                  AS txn_count
    FROM tpcds.store_sales
    WHERE ss_ext_wholesale_cost > 500                 -- filter 1: higher wholesale cost
      AND ss_ext_tax BETWEEN 20 AND 150               -- filter 2: reasonable tax range
    GROUP BY ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk
)
SELECT
    a.ss_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    a.total_net_profit,
    a.total_sales,
    a.txn_count,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY a.total_net_profit DESC)   AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY a.total_sales DESC) AS sales_rownum,
    CASE WHEN cd.cd_gender = 'F' THEN 'Female' ELSE 'Other' END                     AS gender_desc
FROM agg_sales a
JOIN tpcds.customer_demographics cd ON a.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON a.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cd.cd_marital_status = 'S'          -- filter 3: single marital status
  AND hd.hd_vehicle_count >= 2            -- filter 4: at least two vehicles
  AND ib.ib_lower_bound >= 40000          -- filter 5: income band lower bound
ORDER BY profit_rank, a.ss_customer_sk
