WITH
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price AS catalog_sales_amt,
      ss.ss_ext_sales_price AS store_sales_amt,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      wp.wp_type,
      wp.wp_char_count,
      wp.wp_link_count,
      wr.wr_return_amt,
      wr.wr_refunded_cash
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
      AND ss.ss_quantity >= 2
      AND wp.wp_link_count BETWEEN 10 AND 20
      AND wr.wr_return_amt > 150
  ),
  base_alt AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price AS catalog_sales_amt,
      ss.ss_ext_sales_price AS store_sales_amt,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      wp.wp_type,
      wp.wp_char_count,
      wp.wp_link_count,
      wr.wr_return_amt,
      wr.wr_refunded_cash
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
      ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450501 AND 2451000
      AND ss.ss_quantity <= 5
      AND wp.wp_link_count < 15
      AND wr.wr_return_amt > 200
  ),
  combined AS (
    SELECT * FROM base
    UNION
    SELECT * FROM base_alt
  ),
  final_set AS (
    SELECT
      c.cs_order_number,
      c.cs_sold_date_sk,
      c.hd_income_band_sk,
      (c.catalog_sales_amt + c.store_sales_amt) AS total_sales,
      RANK() OVER (
        PARTITION BY c.hd_income_band_sk
        ORDER BY (c.catalog_sales_amt + c.store_sales_amt) DESC
      ) AS sales_rank,
      CASE WHEN c.wr_refunded_cash > 2000 THEN 'HIGH_REFUND' ELSE 'NORMAL' END AS refund_category,
      c.hd_vehicle_count,
      c.wp_char_count,
      (SELECT max(cs_sold_date_sk) FROM catalog_sales) AS max_sold_date_sk
    FROM combined c
    WHERE c.wp_type = 'Content'
      AND c.wp_char_count > 1500
      AND c.hd_vehicle_count >= 2
      AND c.wr_return_amt > 100
  )
SELECT
  fs.cs_order_number,
  fs.cs_sold_date_sk,
  fs.hd_income_band_sk,
  fs.total_sales,
  fs.sales_rank,
  fs.refund_category
FROM (
  SELECT
    cs_order_number,
    cs_sold_date_sk,
    hd_income_band_sk,
    total_sales,
    sales_rank,
    refund_category
  FROM final_set
  EXCEPT
  SELECT
    cs_order_number,
    cs_sold_date_sk,
    hd_income_band_sk,
    total_sales,
    sales_rank,
    refund_category
  FROM final_set
  WHERE hd_income_band_sk = 5
) fs
ORDER BY fs.total_sales DESC
LIMIT 100
