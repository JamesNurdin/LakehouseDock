SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    ib.ib_income_band_sk,
    hd.hd_buy_potential,
    CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    AVG(cs.cs_ext_sales_price) AS avg_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    MIN(cs.cs_ext_sales_price) AS min_catalog_sales,
    MAX(cs.cs_ext_sales_price) AS max_catalog_sales
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk AND cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND hd.hd_dep_count = 2
  AND hd.hd_vehicle_count > 0
  AND ib.ib_lower_bound >= 30000
  AND cc.cc_company = 3
  AND cs.cs_quantity > 5
  AND wp.wp_char_count > 5000
GROUP BY d.d_year,
         d.d_month_seq,
         cc.cc_name,
         ib.ib_income_band_sk,
         hd.hd_buy_potential,
         CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END
UNION ALL
SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    ib.ib_income_band_sk,
    hd.hd_buy_potential,
    CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    AVG(cs.cs_ext_sales_price) AS avg_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    MIN(cs.cs_ext_sales_price) AS min_catalog_sales,
    MAX(cs.cs_ext_sales_price) AS max_catalog_sales
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk AND cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND hd.hd_dep_count = 4
  AND hd.hd_vehicle_count > 1
  AND ib.ib_lower_bound >= 10000
  AND cc.cc_company = 4
  AND cs.cs_quantity > 10
  AND wp.wp_char_count > 2000
GROUP BY d.d_year,
         d.d_month_seq,
         cc.cc_name,
         ib.ib_income_band_sk,
         hd.hd_buy_potential,
         CASE WHEN ib.ib_upper_bound > 100000 THEN 'High Income' ELSE 'Low Income' END
ORDER BY d_year DESC, total_catalog_sales DESC
LIMIT 100
