WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt,
        CASE WHEN SUM(cs_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM tpcds.catalog_sales
    WHERE cs_ext_list_price > 2000
      AND cs_quantity >= 2
      AND cs_ext_discount_amt IS NOT NULL
    GROUP BY cs_call_center_sk, cs_sold_date_sk
)
SELECT
    cc.cc_call_center_id,
    d.d_year,
    sa.total_sales,
    sa.total_discount,
    sa.order_cnt,
    sa.profit_level,
    (
        SELECT SUM(cs2.cs_ext_discount_amt)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
          AND cs2.cs_sold_date_sk = d.d_date_sk
    ) AS total_center_discount_all_dates,
    CASE
        WHEN cc.cc_gmt_offset = -6.00 THEN 'Central'
        WHEN cc.cc_gmt_offset = -5.00 THEN 'Eastern'
        ELSE 'Other'
    END AS gmt_region
FROM sales_agg sa
JOIN tpcds.call_center cc
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.date_dim d
    ON sa.cs_sold_date_sk = d.d_date_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_gmt_offset = -6.00
  AND d.d_year = 1998
ORDER BY sa.total_sales DESC
LIMIT 100
