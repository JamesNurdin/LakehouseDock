WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        s.s_store_name AS store_name,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND i.i_category = 'Electronics'
    GROUP BY i.i_item_id, s.s_store_name
),
catalog_sales_agg AS (
    SELECT
        i.i_item_id,
        cc.cc_name AS store_name,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cc.cc_state = 'CA'
      AND i.i_category = 'Electronics'
    GROUP BY i.i_item_id, cc.cc_name
)
SELECT i_item_id,
       store_name,
       total_sales
FROM store_sales_agg
UNION ALL
SELECT i_item_id,
       store_name,
       total_sales
FROM catalog_sales_agg
ORDER BY total_sales DESC
LIMIT 100
