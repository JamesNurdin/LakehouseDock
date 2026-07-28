WITH sales_a AS (
    SELECT
        i.i_item_id,
        i.i_category,
        cc.cc_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
        MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND cd.cd_education_status = 'Advanced Degree'
      AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0)
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450843
    GROUP BY i.i_item_id, i.i_category, cc.cc_name
),
sales_b AS (
    SELECT
        i.i_item_id,
        i.i_category,
        cc.cc_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
        MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE td.t_hour BETWEEN 18 AND 23
      AND cc.cc_state = 'TX'
      AND i.i_brand = 'BrandY'
      AND cd.cd_education_status = 'Primary'
      AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand <= 10)
      AND cs.cs_sold_date_sk BETWEEN 2450844 AND 2451074
    GROUP BY i.i_item_id, i.i_category, cc.cc_name
)
SELECT
    i_item_id,
    i_category,
    cc_name,
    total_sales,
    avg_discount,
    sales_cnt,
    min_sold_date_sk,
    max_sold_date_sk
FROM sales_a
UNION ALL
SELECT
    i_item_id,
    i_category,
    cc_name,
    total_sales,
    avg_discount,
    sales_cnt,
    min_sold_date_sk,
    max_sold_date_sk
FROM sales_b
ORDER BY total_sales DESC
LIMIT 100
