WITH intersect_orders AS (
    SELECT cs.cs_order_number AS order_num
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 1000
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
      AND ws.ws_net_paid > 1000
),
all_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name,
        cp.cp_catalog_number,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        sm.sm_ship_mode_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        wsite.web_name,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_catalog_number IN (7, 10, 13)
      AND i.i_brand = 'Brand#12'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450995
      AND ws.ws_net_paid > 500
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_item_sk = cs.cs_item_sk
            AND sr2.sr_return_quantity > 0
      )
      AND cs.cs_order_number IN (SELECT order_num FROM intersect_orders)
),
union_agg AS (
    SELECT i_item_id,
           cc_name AS dim_name,
           total_paid,
           orders,
           total_qty
    FROM (
        SELECT i.i_item_id,
               cc.cc_name,
               SUM(cs.cs_net_paid) AS total_paid,
               COUNT(DISTINCT cs.cs_order_number) AS orders,
               SUM(cs.cs_quantity) AS total_qty
        FROM all_data ad
        JOIN catalog_sales cs ON cs.cs_order_number = ad.cs_order_number
        JOIN call_center cc ON cc.cc_call_center_sk = ad.cs_call_center_sk
        JOIN item i ON i.i_item_sk = ad.cs_item_sk
        GROUP BY i.i_item_id, cc.cc_name
    )
    UNION
    SELECT i_item_id,
           web_name AS dim_name,
           total_paid,
           orders,
           total_qty
    FROM (
        SELECT i.i_item_id,
               wsite.web_name,
               SUM(ws.ws_net_paid) AS total_paid,
               COUNT(DISTINCT ws.ws_order_number) AS orders,
               SUM(ws.ws_quantity) AS total_qty
        FROM all_data ad
        JOIN web_sales ws ON ws.ws_order_number = ad.ws_order_number
        JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
        JOIN item i ON i.i_item_sk = ad.cs_item_sk
        GROUP BY i.i_item_id, wsite.web_name
    )
)
SELECT
    COALESCE(i_item_id, 'ALL') AS item_id,
    dim_name,
    SUM(total_paid) AS sum_total_paid,
    SUM(orders) AS sum_orders,
    SUM(total_qty) AS sum_quantity,
    (
        SELECT COALESCE(SUM(inv.inv_quantity_on_hand), 0)
        FROM inventory inv
        JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
        WHERE i2.i_item_id = union_agg.i_item_id
    ) AS total_inventory
FROM union_agg
GROUP BY CUBE(i_item_id, dim_name)
ORDER BY sum_total_paid DESC
LIMIT 100
