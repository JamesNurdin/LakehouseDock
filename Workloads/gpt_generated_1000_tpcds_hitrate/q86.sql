WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        MIN(cp.cp_department) AS cp_department,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        MAX(cs.cs_ext_sales_price) AS max_sales_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_type = 'A'
      AND cs.cs_ext_wholesale_cost > 1000
      AND cs.cs_ext_list_price BETWEEN 1500 AND 8000
      AND cs.cs_quantity >= 2
    GROUP BY cs.cs_item_sk, cs.cs_call_center_sk
)
SELECT DISTINCT
    i.i_item_id,
    i.i_class,
    cc.cc_name,
    sa.cp_department,
    sr.sr_fee,
    sa.total_sales,
    sa.avg_discount,
    sa.sales_cnt,
    sa.max_sales_price
FROM sales_agg sa
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
JOIN call_center cc ON cc.cc_call_center_sk = sa.cs_call_center_sk
WHERE i.i_class = 'hockey'
  AND i.i_wholesale_cost > (
        SELECT MIN(i2.i_wholesale_cost)
        FROM item i2
        WHERE i2.i_color = 'red'
    )
  AND sr.sr_fee > 20
  AND sr.sr_return_quantity BETWEEN 1 AND 5
  AND cc.cc_division_name = 'Division 1'
ORDER BY sa.total_sales DESC
LIMIT 100
