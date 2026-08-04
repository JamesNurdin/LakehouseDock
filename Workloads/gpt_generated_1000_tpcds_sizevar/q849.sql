WITH
  ws_agg AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY ws.ws_item_sk
  ),
  sr_agg AS (
    SELECT sr.sr_item_sk,
           SUM(sr.sr_return_amt) AS total_returns,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY sr.sr_item_sk
  ),
  excluded_items AS (
    SELECT i_item_id FROM item WHERE i_category = 'Books'
    EXCEPT
    SELECT i_item_id FROM item WHERE i_current_price < 10
  ),
  union_items AS (
    SELECT i_item_id FROM item WHERE i_current_price > 100
    UNION
    SELECT i_item_id FROM item WHERE i_current_price < 20
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  ws_agg.total_sales,
  sr_agg.total_returns,
  (
    SELECT COUNT(*)
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
  ) AS inventory_cnt,
  cust.c_first_name,
  cust.c_last_name,
  (
    SELECT MAX(p2.p_cost)
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
  ) AS max_promo_cost
FROM item i
JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk
JOIN inventory inv_direct ON i.i_item_sk = inv_direct.inv_item_sk
JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer cust ON sr.sr_customer_sk = cust.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
JOIN web_sales ws2 ON i.i_item_sk = ws2.ws_item_sk
JOIN time_dim td2 ON ws2.ws_sold_time_sk = td2.t_time_sk
JOIN customer cust_ship ON ws2.ws_ship_customer_sk = cust_ship.c_customer_sk
WHERE i.i_item_id IN (SELECT i_item_id FROM union_items)
  AND i.i_item_id NOT IN (SELECT i_item_id FROM excluded_items)
  AND i.i_item_id IN (
        SELECT i1.i_item_id FROM item i1
        INTERSECT
        SELECT i2.i_item_id FROM item i2 WHERE i2.i_brand = 'Brand#12'
      )
  AND EXISTS (
        SELECT 1 FROM web_site wsite
        WHERE wsite.web_site_sk = ws2.ws_web_site_sk
          AND wsite.web_name = 'SiteA'
      )
ORDER BY ws_agg.total_sales DESC
LIMIT 100
