WITH sales_agg AS (
    SELECT
        dd.d_year,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
        SUM(CASE WHEN cs.cs_coupon_amt > 500 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_coupon_sales
    FROM store_sales ss
    JOIN date_dim dd
        ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = dd.d_date_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
    WHERE dd.d_year = 2001
      AND dd.d_dow = 5
      AND i.i_brand_id IN (8015002, 7004003, 5003002)
      AND i.i_category_id = 9
      AND td.t_hour BETWEEN 9 AND 17
      AND cs.cs_coupon_amt > 100
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = dd.d_date_sk
            AND cs2.cs_ext_discount_amt > 500
      )
    GROUP BY dd.d_year, i.i_brand, i.i_category
)
SELECT
    s.d_year,
    s.i_brand,
    s.i_category,
    s.store_sales_amount,
    s.catalog_sales_amount,
    s.store_txn_cnt,
    s.avg_coupon_amt,
    s.high_coupon_sales,
    CASE
        WHEN s.avg_coupon_amt > 300 THEN 'Very High'
        WHEN s.avg_coupon_amt > 150 THEN 'High'
        ELSE 'Normal'
    END AS coupon_category,
    SUM(s.store_sales_amount) OVER (PARTITION BY s.d_year) AS total_store_sales_year,
    ROW_NUMBER() OVER (ORDER BY s.store_sales_amount DESC) AS sales_rank
FROM sales_agg s
ORDER BY s.store_sales_amount DESC
LIMIT 100
