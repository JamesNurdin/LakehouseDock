WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    union_sales AS (
        SELECT cs.cs_order_number AS order_id,
               cs.cs_sold_date_sk,
               cs.cs_sold_time_sk,
               cs.cs_item_sk,
               cs.cs_promo_sk,
               cs.cs_call_center_sk,
               cs.cs_quantity,
               cs.cs_net_paid
        FROM catalog_sales cs
        UNION
        SELECT ws.ws_order_number AS order_id,
               ws.ws_sold_date_sk,
               ws.ws_sold_time_sk,
               ws.ws_item_sk,
               ws.ws_promo_sk,
               NULL AS cs_call_center_sk,
               ws.ws_quantity,
               ws.ws_net_paid
        FROM web_sales ws
    ),
    catalog_only_orders AS (
        SELECT cs_order_number AS order_id FROM catalog_sales
        EXCEPT
        SELECT ws_order_number FROM web_sales
    ),
    max_net_paid AS (
        SELECT MAX(cs_net_paid) AS max_paid FROM catalog_sales
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY ia.total_qty DESC) AS rn,
    c.cc_name,
    i.i_item_id,
    td.t_time,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    ia.total_qty,
    (
        SELECT SUM(p_sub.p_cost)
        FROM promotion p_sub
        WHERE p_sub.p_item_sk = i.i_item_sk
    ) AS total_promo_cost,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_item_sk = i.i_item_sk
    ) AS item_sales_count,
    CASE
        WHEN cs.cs_net_paid > (SELECT max_paid FROM max_net_paid) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS pay_category
FROM union_sales us
JOIN catalog_sales cs
    ON us.order_id = cs.cs_order_number
LEFT JOIN web_sales ws
    ON us.order_id = ws.ws_order_number
JOIN call_center c
    ON cs.cs_call_center_sk = c.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN inv_agg ia
    ON i.i_item_sk = ia.inv_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN promotion p2
    ON p2.p_item_sk = i.i_item_sk
JOIN catalog_only_orders co
    ON cs.cs_order_number = co.order_id
WHERE td.t_hour BETWEEN 8 AND 16
  AND EXISTS (
        SELECT 1
        FROM inventory inv_check
        WHERE inv_check.inv_item_sk = i.i_item_sk
          AND inv_check.inv_quantity_on_hand > 0
    )
GROUP BY
    c.cc_name,
    i.i_item_id,
    td.t_time,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    ia.total_qty,
    i.i_item_sk
ORDER BY rn
LIMIT 100
