WITH ss_agg AS (
        SELECT
            ss_store_sk,
            ss_sold_date_sk,
            SUM(ss_ext_sales_price) AS store_total_sales,
            SUM(ss_net_profit)       AS store_total_profit,
            COUNT(*)                 AS store_sales_cnt
        FROM store_sales
        WHERE ss_sales_price > 30
          AND ss_quantity >= 2
          AND ss_ext_discount_amt < 500
        GROUP BY ss_store_sk, ss_sold_date_sk
    ),
    cs_agg AS (
        SELECT
            cs_bill_customer_sk,
            cs_sold_date_sk,
            cs_sold_time_sk,
            SUM(cs_ext_sales_price) AS catalog_total_sales,
            AVG(cs_coupon_amt)      AS avg_coupon,
            COUNT(*)                AS catalog_orders
        FROM catalog_sales
        WHERE cs_sales_price > 20
          AND cs_quantity >= 1
        GROUP BY cs_bill_customer_sk, cs_sold_date_sk, cs_sold_time_sk
    ),
    wr_agg AS (
        SELECT
            wr_refunded_customer_sk,
            wr_returned_date_sk,
            SUM(wr_return_amt) AS web_return_total,
            COUNT(*)           AS web_return_cnt
        FROM web_returns
        WHERE wr_return_amt > 10
        GROUP BY wr_refunded_customer_sk, wr_returned_date_sk
    )
SELECT
    d.d_year,
    s.s_store_name,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ss_agg.store_total_sales,
    ss_agg.store_total_profit,
    ss_agg.store_sales_cnt,
    cs_agg.catalog_total_sales,
    cs_agg.avg_coupon,
    cs_agg.catalog_orders,
    t.t_hour,
    wr_agg.web_return_total,
    wr_agg.web_return_cnt,
    wr.wr_return_amt            AS raw_web_return_amt,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    wp.wp_url,
    web_site.web_name
FROM ss_agg
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN cs_agg
  ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON cs_agg.cs_sold_time_sk = t.t_time_sk
JOIN customer c
  ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
  AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
  AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN wr_agg
  ON wr_agg.wr_refunded_customer_sk = c.c_customer_sk
  AND wr_agg.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN web_site
  ON web_site.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
  AND s.s_state = 'CA'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '700-1000'
  AND s.s_number_employees > 100
  AND d.d_month_seq = 12
ORDER BY d.d_year DESC, s.s_store_name
LIMIT 100
