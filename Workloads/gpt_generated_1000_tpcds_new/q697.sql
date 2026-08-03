WITH sampled_inventory AS (
   SELECT *
   FROM inventory
   TABLESAMPLE BERNOULLI (10)
   WHERE inv_quantity_on_hand > 500
),
joined_data AS (
   SELECT
        s.s_store_id,
        s.s_state,
        i.i_category,
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_return_amount,
        cr.cr_order_number,
        cc.cc_gmt_offset,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag,
        (SELECT SUM(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_item_sk = i.i_item_sk) AS total_inventory_for_item,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank
   FROM sampled_inventory inv
   JOIN item i                     ON inv.inv_item_sk = i.i_item_sk
   JOIN store_sales ss            ON ss.ss_item_sk = i.i_item_sk
   JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN web_sales ws              ON ws.ws_item_sk = i.i_item_sk
   JOIN web_site site             ON ws.ws_web_site_sk = site.web_site_sk
   JOIN catalog_returns cr       ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp           ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE i.i_current_price BETWEEN 10 AND 100
     AND s.s_state = 'CA'
     AND cc.cc_gmt_offset > -5.00
     AND ws.ws_quantity > 1
     AND cr.cr_return_quantity > 0
     AND ca.ca_country = 'United States'
),
order_diff AS (
   SELECT cr_order_number
   FROM catalog_returns
   EXCEPT
   SELECT ws_order_number
   FROM web_sales
),
filtered_data AS (
   SELECT *
   FROM joined_data jd
   WHERE jd.cr_order_number IN (SELECT cr_order_number FROM order_diff)
)
SELECT
   s_state,
   i_category,
   SUM(ss_net_paid)        AS total_store_sales,
   SUM(ws_net_paid)        AS total_web_sales,
   SUM(cr_return_amount)   AS total_return_amount,
   AVG(total_inventory_for_item) AS avg_inventory_per_item,
   MAX(sales_rank)         AS max_sales_rank,
   CASE WHEN s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag
FROM filtered_data
GROUP BY CUBE (s_state, i_category)
HAVING SUM(ss_net_paid) > 0
ORDER BY total_store_sales DESC
LIMIT 100
