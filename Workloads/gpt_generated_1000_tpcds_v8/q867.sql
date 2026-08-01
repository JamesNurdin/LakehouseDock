WITH intersect_items AS (
   SELECT inv_item_sk FROM inventory
   INTERSECT
   SELECT wr_item_sk FROM web_returns
),
cc_data AS (
   SELECT cc.cc_call_center_sk,
          cc.cc_name,
          d.d_date_sk,
          d.d_date,
          d.d_year
   FROM call_center cc
   JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
cp_data AS (
   SELECT cp.cp_catalog_page_sk,
          cp.cp_department,
          d.d_date_sk AS cp_date_sk,
          d.d_date AS cp_date,
          d.d_year AS cp_year
   FROM catalog_page cp
   JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)
SELECT
   COALESCE(cd.cc_call_center_sk, -1) AS call_center_sk,
   cd.cc_name,
   pd.cp_catalog_page_sk,
   pd.cp_department,
   COALESCE(cd.d_date, pd.cp_date) AS activity_date,
   wr_agg.total_return_qty,
   ii.inv_item_sk,
   ROW_NUMBER() OVER (ORDER BY COALESCE(cd.d_date, pd.cp_date) DESC) AS rn
FROM cc_data cd
FULL OUTER JOIN cp_data pd
   ON cd.d_date_sk = pd.cp_date_sk
LEFT JOIN intersect_items ii
   ON ii.inv_item_sk = pd.cp_catalog_page_sk
CROSS JOIN LATERAL (
   SELECT COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_qty
   FROM web_returns wr
   WHERE wr.wr_returned_date_sk = COALESCE(cd.d_date_sk, pd.cp_date_sk)
) AS wr_agg
WHERE EXISTS (
   SELECT 1 FROM intersect_items ix WHERE ix.inv_item_sk = COALESCE(cd.cc_call_center_sk, pd.cp_catalog_page_sk)
)
ORDER BY rn
OFFSET 0 LIMIT 100
