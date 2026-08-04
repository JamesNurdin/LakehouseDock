WITH catalog AS (
    SELECT cs.*
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > (SELECT AVG(cs_quantity) FROM tpcds.catalog_sales)
),
store AS (
    SELECT ss.*
    FROM tpcds.store_sales ss TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    i.i_brand,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(c.cs_ext_sales_price) AS total_catalog_sales,
    SUM(s.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT c.cs_order_number) AS catalog_orders,
    AVG(i.i_current_price) AS avg_item_price,
    MAX(wr.wr_return_amt) AS max_return_amount,
    MIN(ws.web_gmt_offset) AS min_gmt_offset
FROM catalog c
JOIN tpcds.date_dim d
  ON c.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
  ON c.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.item i
  ON c.cs_item_sk = i.i_item_sk
JOIN LATERAL (
    SELECT AVG(i2.i_current_price) AS brand_avg_price
    FROM tpcds.item i2
    WHERE i2.i_brand = i.i_brand
) la
  ON true
JOIN tpcds.promotion p
  ON c.cs_promo_sk = p.p_promo_sk
JOIN tpcds.customer cu
  ON c.cs_bill_customer_sk = cu.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON c.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON c.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
  ON s.ss_sold_date_sk = d.d_date_sk
 AND s.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_returned_time_sk = t.t_time_sk
 AND wr.wr_item_sk = i.i_item_sk
 AND wr.wr_refunded_customer_sk = cu.c_customer_sk
 AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
 AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
FULL OUTER JOIN tpcds.web_page wp
  ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND hd.hd_vehicle_count >= 2
    AND cd.cd_gender = 'M'
    AND wp.wp_autogen_flag = 'N'
GROUP BY
    d.d_year,
    i.i_brand,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_vehicle_count
ORDER BY total_catalog_sales DESC
LIMIT 100
