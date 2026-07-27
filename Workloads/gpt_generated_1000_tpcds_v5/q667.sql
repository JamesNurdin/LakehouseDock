WITH sales_summary AS (
   SELECT
      d.d_year,
      c.c_customer_sk,
      c.c_customer_id,
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      AVG(cs.cs_ext_discount_amt) AS avg_discount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2001
     AND cs.cs_ext_sales_price > 1000
     AND cs.cs_quantity >= 2
   GROUP BY d.d_year, c.c_customer_sk, c.c_customer_id, hd.hd_demo_sk, hd.hd_income_band_sk
),
store_return_agg AS (
   SELECT
      sr.sr_customer_sk,
      MIN(sr.sr_store_sk) AS store_sk,
      SUM(sr.sr_return_amt) AS total_store_return_amt,
      COUNT(sr.sr_return_quantity) AS store_return_cnt
   FROM store_returns sr
   GROUP BY sr.sr_customer_sk
),
web_return_agg AS (
   SELECT
      wp.wp_customer_sk AS customer_sk,
      SUM(wr.wr_return_amt) AS total_web_return_amt,
      COUNT(wr.wr_return_quantity) AS web_return_cnt,
      MAX(wp.wp_type) AS any_wp_type
   FROM web_returns wr
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   GROUP BY wp.wp_customer_sk
)
SELECT
   ss.d_year,
   ss.c_customer_id,
   ss.hd_income_band_sk,
   ss.total_sales,
   ss.sales_cnt,
   ss.avg_discount,
   COALESCE(sra.total_store_return_amt, 0) AS total_store_return_amt,
   COALESCE(sra.store_return_cnt, 0) AS store_return_cnt,
   COALESCE(wra.total_web_return_amt, 0) AS total_web_return_amt,
   COALESCE(wra.web_return_cnt, 0) AS web_return_cnt,
   COALESCE(s.s_store_name, 'No Store') AS store_name,
   COALESCE(ws.web_name, 'No Site') AS web_site_name,
   COALESCE(wra.any_wp_type, 'none') AS web_page_type
FROM sales_summary ss
LEFT JOIN store_return_agg sra ON sra.sr_customer_sk = ss.c_customer_sk
LEFT JOIN store s ON sra.store_sk = s.s_store_sk
LEFT JOIN web_return_agg wra ON wra.customer_sk = ss.c_customer_sk
JOIN date_dim d_ws ON d_ws.d_year = ss.d_year
LEFT JOIN web_site ws ON ws.web_open_date_sk = d_ws.d_date_sk
WHERE ss.d_year BETWEEN 2000 AND 2002
  AND ss.total_sales > 5000
  AND ss.hd_income_band_sk IS NOT NULL
ORDER BY ss.total_sales DESC
LIMIT 100
