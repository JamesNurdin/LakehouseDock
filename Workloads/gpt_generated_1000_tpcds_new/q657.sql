WITH sales_data AS (
   SELECT
       cp.cp_catalog_page_sk,
       cp.cp_department,
       cp.cp_type,
       cp.cp_catalog_number,
       d.d_date,
       d.d_year,
       hd.hd_income_band_sk,
       hd.hd_dep_count,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cp.cp_type IN ('monthly', 'quarterly')
     AND cp.cp_catalog_number BETWEEN 8 AND 20
     AND hd.hd_income_band_sk IN (3, 5, 12)
     AND hd.hd_dep_count >= 2
     AND d.d_year = 2001
   GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_type,
            cp.cp_catalog_number, d.d_date, d.d_year,
            hd.hd_income_band_sk, hd.hd_dep_count
   HAVING SUM(cs.cs_ext_sales_price) > 10000
),

returns_data AS (
   SELECT
       cp.cp_catalog_page_sk,
       d.d_date,
       SUM(cr.cr_return_amount) AS total_returns,
       COUNT(*) AS return_cnt,
       MAX(r.r_reason_desc) AS top_reason
   FROM catalog_returns cr
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc NOT LIKE '%damaged%'
     AND d.d_year = 2001
   GROUP BY cp.cp_catalog_page_sk, d.d_date
),

store_ret_data AS (
   SELECT
       sr.sr_reason_sk,
       d.d_date,
       SUM(sr.sr_return_amt) AS store_return_amt,
       COUNT(*) AS store_return_cnt
   FROM store_returns sr
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN household_demographics hd
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   WHERE hd.hd_income_band_sk = 5
     AND d.d_month_seq BETWEEN 1200 AND 1210
   GROUP BY sr.sr_reason_sk, d.d_date
),

sales_without_returns AS (
   SELECT sd.cp_catalog_page_sk, sd.d_date
   FROM sales_data sd
   EXCEPT
   SELECT rd.cp_catalog_page_sk, rd.d_date
   FROM returns_data rd
)

SELECT
    sd.cp_catalog_page_sk,
    sd.cp_department,
    sd.cp_type,
    sd.d_date,
    sd.total_sales,
    sd.total_profit,
    rd.total_returns,
    COALESCE(rd.total_returns, 0) AS returns_amount,
    CASE
        WHEN sd.total_sales - COALESCE(rd.total_returns, 0) > 5000 THEN 'High Net'
        ELSE 'Low Net'
    END AS net_category,
    RANK() OVER (PARTITION BY sd.cp_department ORDER BY sd.total_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM sales_without_returns swr
        WHERE swr.cp_catalog_page_sk = sd.cp_catalog_page_sk) AS missing_return_days
FROM sales_data sd
LEFT JOIN returns_data rd
  ON sd.cp_catalog_page_sk = rd.cp_catalog_page_sk
 AND sd.d_date = rd.d_date
LEFT JOIN store_ret_data srt
  ON srt.d_date = sd.d_date
WHERE (sd.cp_catalog_page_sk, sd.d_date) IN (SELECT * FROM sales_without_returns)
ORDER BY sd.total_sales DESC
LIMIT 100
