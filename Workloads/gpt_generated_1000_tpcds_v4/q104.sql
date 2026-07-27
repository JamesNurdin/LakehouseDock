WITH catalog_agg AS (
    SELECT
        cs_warehouse_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS catalog_sales_total,
        AVG(cs_ext_discount_amt) AS avg_catalog_discount,
        COUNT(*) AS catalog_txn_cnt
    FROM tpcds.catalog_sales
    WHERE cs_ext_tax > 20.00
      AND cs_ext_discount_amt BETWEEN 800.00 AND 1500.00
      AND cs_list_price >= 100.00
    GROUP BY cs_warehouse_sk, cs_sold_time_sk
)
SELECT
    w.w_warehouse_name,
    t.t_shift,
    SUM(ca.catalog_sales_total) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT ca.cs_warehouse_sk) AS warehouse_cnt,
    AVG(ss.ss_coupon_amt) AS avg_store_coupon_amt,
    MIN(ss.ss_wholesale_cost) AS min_store_wholesale_cost,
    MAX(ss.ss_wholesale_cost) AS max_store_wholesale_cost
FROM catalog_agg ca
JOIN tpcds.warehouse w
    ON ca.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.time_dim t
    ON ca.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
WHERE w.w_county = 'Bronx County'
  AND w.w_gmt_offset = -5.00
  AND ss.ss_hdemo_sk IN (791, 2484)
  AND ss.ss_coupon_amt < 500.00
GROUP BY w.w_warehouse_name, t.t_shift
ORDER BY total_catalog_sales DESC
LIMIT 100
