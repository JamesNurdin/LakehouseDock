WITH intersect_items AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450500 AND 2450600
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450500 AND 2450600
)

SELECT
    i.i_item_sk               AS item_sk,
    i.i_product_name          AS product_name,
    CASE
        WHEN td.t_shift = 'first'  THEN 'Morning'
        WHEN td.t_shift = 'second' THEN 'Afternoon'
        ELSE 'Other'
    END                        AS category_label,
    ss_agg.ss_total           AS total_sales,
    inv_l.inv_quantity_on_hand AS inv_qty,
    (SELECT COUNT(*)
       FROM store_sales s2
      WHERE s2.ss_item_sk = i.i_item_sk) AS txn_count
FROM (
    SELECT ss.ss_item_sk,
           SUM(ss.ss_ext_sales_price) AS ss_total,
           ss.ss_sold_time_sk
    FROM store_sales ss
    JOIN intersect_items ii ON ss.ss_item_sk = ii.item_sk
    GROUP BY ss.ss_item_sk, ss.ss_sold_time_sk
) ss_agg
JOIN item i
  ON i.i_item_sk = ss_agg.ss_item_sk
JOIN time_dim td
  ON td.t_time_sk = ss_agg.ss_sold_time_sk
LEFT JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
    ORDER BY inv.inv_quantity_on_hand DESC
    LIMIT 1
) inv_l ON TRUE
WHERE i.i_item_sk IN (
    SELECT inv.inv_item_sk
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 5
)

UNION ALL

SELECT
    i2.i_item_sk               AS item_sk,
    i2.i_product_name          AS product_name,
    CASE
        WHEN p.p_discount_active = 'Y' THEN 'PromotionActive'
        ELSE 'NoPromo'
    END                        AS category_label,
    ws_agg.ws_total           AS total_sales,
    inv_l2.inv_quantity_on_hand AS inv_qty,
    (SELECT COUNT(*)
       FROM web_sales w2
      WHERE w2.ws_item_sk = i2.i_item_sk) AS txn_count
FROM (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_ext_sales_price) AS ws_total,
           ws.ws_sold_time_sk,
           ws.ws_promo_sk,
           ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN intersect_items ii ON ws.ws_item_sk = ii.item_sk
    GROUP BY ws.ws_item_sk, ws.ws_sold_time_sk, ws.ws_promo_sk, ws.ws_bill_customer_sk
) ws_agg
FULL OUTER JOIN promotion p
  ON p.p_promo_sk = ws_agg.ws_promo_sk
JOIN item i2
  ON i2.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i2.i_item_sk
    ORDER BY inv.inv_quantity_on_hand DESC
    LIMIT 1
) inv_l2 ON TRUE
WHERE i2.i_item_sk IN (
    SELECT inv.inv_item_sk
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 5
)

ORDER BY category_label DESC, total_sales DESC
LIMIT 100
