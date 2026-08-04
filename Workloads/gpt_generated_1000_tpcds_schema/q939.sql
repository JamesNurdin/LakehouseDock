WITH
cat_ws_diff AS (
   SELECT cs.cs_item_sk
   FROM catalog_sales cs
   EXCEPT
   SELECT ws.ws_item_sk
   FROM web_sales ws
),
base_agg AS (
   SELECT
       i.i_item_sk,
       i.i_product_name,
       d.d_year,
       SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
       SUM(ss.ss_ext_sales_price) AS store_sales_total,
       SUM(ws.ws_ext_sales_price) AS web_sales_total,
       SUM(inv.inv_quantity_on_hand) AS total_inventory,
       CASE
           WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High'
           WHEN SUM(ss.ss_net_profit) BETWEEN 50000 AND 100000 THEN 'Medium'
           ELSE 'Low'
       END AS profit_category
   FROM
       store_sales ss
       RIGHT OUTER JOIN item i ON ss.ss_item_sk = i.i_item_sk
       LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
       LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
       LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
       LEFT JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
       LEFT JOIN time_dim t ON t.t_time_sk = cs.cs_sold_time_sk
       LEFT JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
       LEFT JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
       LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
       LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
       LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
       LEFT JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
   WHERE
       i.i_brand = 'BrandX'
       AND i.i_category = 'Electronics'
       AND i.i_color = 'Red'
       AND i.i_size = 'M'
       AND i.i_current_price > 100
   GROUP BY i.i_item_sk, i.i_product_name, d.d_year
),
final AS (
   SELECT
       ba.i_item_sk,
       ba.i_product_name,
       ba.d_year,
       ba.catalog_sales_total,
       ba.store_sales_total,
       ba.web_sales_total,
       ba.total_inventory,
       ba.profit_category,
       (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = ba.i_item_sk) AS return_cnt,
       CASE WHEN cws.cs_item_sk IS NOT NULL THEN 1 ELSE 0 END AS catalog_no_web_flag
   FROM base_agg ba
   LEFT JOIN cat_ws_diff cws ON cws.cs_item_sk = ba.i_item_sk
)
SELECT *
FROM final
ORDER BY catalog_sales_total DESC, i_product_name
LIMIT 100
