WITH
  inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk
  ),
  cat_agg AS (
    SELECT cs_item_sk,
           SUM(cs_ext_sales_price) AS cat_sales
    FROM catalog_sales
    WHERE cs_ext_sales_price > 0
    GROUP BY cs_item_sk
  ),
  store_agg AS (
    SELECT ss_item_sk,
           SUM(ss_ext_sales_price) AS store_sales
    FROM store_sales
    GROUP BY ss_item_sk
  ),
  item_excl AS (
    SELECT i_item_sk FROM item
    EXCEPT
    SELECT cs_item_sk FROM catalog_sales
  )
SELECT
  i.i_category,
  s.s_state,
  SUM(coalesce(cat_agg.cat_sales, 0) +
      coalesce(store_agg.store_sales, 0) +
      coalesce(ws.ws_ext_sales_price, 0)) AS total_sales,
  SUM(inv_agg.total_on_hand) AS total_inventory,
  RANK() OVER (PARTITION BY i.i_category
               ORDER BY SUM(coalesce(cat_agg.cat_sales, 0) +
                            coalesce(store_agg.store_sales, 0) +
                            coalesce(ws.ws_ext_sales_price, 0)) DESC) AS category_rank,
  CASE
    WHEN SUM(coalesce(cat_agg.cat_sales, 0) +
             coalesce(store_agg.store_sales, 0) +
             coalesce(ws.ws_ext_sales_price, 0)) > 100000 THEN 'High'
    ELSE 'Low'
  END AS sales_level,
  (
    SELECT avg(i2.i_current_price)
    FROM item i2
    WHERE i2.i_category = i.i_category
  ) AS avg_category_price
FROM item i
JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
JOIN cat_agg ON i.i_item_sk = cat_agg.cs_item_sk
JOIN store_agg ON i.i_item_sk = store_agg.ss_item_sk
JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE
  c.c_birth_month IN (1, 4, 12)
  AND cc.cc_state = s.s_state
  AND EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_promo_sk = cs.cs_promo_sk
      AND p2.p_discount_active = 'Y'
  )
  AND i.i_item_sk IN (SELECT i_item_sk FROM item_excl)
GROUP BY GROUPING SETS (
    (i.i_category, s.s_state),
    (i.i_category),
    (s.s_state),
    ()
)
HAVING SUM(coalesce(cat_agg.cat_sales, 0) +
            coalesce(store_agg.store_sales, 0) +
            coalesce(ws.ws_ext_sales_price, 0)) > 50000
ORDER BY total_sales DESC
LIMIT 100
