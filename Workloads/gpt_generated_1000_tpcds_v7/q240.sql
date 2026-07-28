WITH joined AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       i.i_current_price,
       cp.cp_catalog_page_id,
       cp.cp_department,
       cc.cc_name,
       cc.cc_state,
       hd.hd_demo_sk,
       hd.hd_vehicle_count,
       cs.cs_ext_sales_price AS cs_sales,
       ss.ss_ext_sales_price AS ss_sales,
       ws.ws_ext_sales_price AS ws_sales,
       web.web_site_id,
       web.web_tax_percentage
   FROM catalog_sales cs
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_sales ss
     ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN web_site web
     ON ws.ws_web_site_sk = web.web_site_sk
   WHERE i.i_current_price > 50
     AND cc.cc_state = 'CA'
     AND cp.cp_department = 'Electronics'
     AND web.web_tax_percentage >= 0.09
     AND hd.hd_vehicle_count > 1
),
agg AS (
   SELECT
       i_item_id,
       i_product_name,
       cp_catalog_page_id,
       cc_name,
       web_site_id,
       SUM(COALESCE(cs_sales, 0) + COALESCE(ss_sales, 0) + COALESCE(ws_sales, 0)) AS total_sales
   FROM joined
   GROUP BY i_item_id, i_product_name, cp_catalog_page_id, cc_name, web_site_id
)
SELECT
    i_item_id,
    i_product_name,
    cp_catalog_page_id,
    cc_name,
    web_site_id,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY cp_catalog_page_id ORDER BY total_sales DESC) AS rank_in_page
FROM agg
ORDER BY total_sales DESC
LIMIT 100
