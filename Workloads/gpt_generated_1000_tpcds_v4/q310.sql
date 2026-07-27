WITH latest_inventory AS (
        SELECT i.inv_item_sk,
               i.inv_quantity_on_hand
        FROM inventory i
        WHERE i.inv_date_sk = (
                SELECT MAX(inv_date_sk)
                FROM inventory
                WHERE inv_item_sk = i.inv_item_sk
        )
    )
SELECT
        i.i_item_id,
        i.i_product_name,
        cc.cc_name,
        cp.cp_catalog_page_number,
        td.t_hour,
        SUM(cs.cs_ext_sales_price)                         AS total_sales,
        SUM(cs.cs_net_profit)                              AS total_profit,
        SUM(cs.cs_quantity)                               AS total_quantity,
        li.inv_quantity_on_hand,
        (SELECT COUNT(DISTINCT cr2.cr_return_quantity)
         FROM catalog_returns cr2
         WHERE cr2.cr_order_number = cs.cs_order_number) AS distinct_return_quantity_count,
        RANK() OVER (PARTITION BY i.i_brand ORDER BY SUM(cs.cs_net_profit) DESC) AS brand_profit_rank
FROM catalog_sales cs
JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
JOIN latest_inventory li
     ON i.i_item_sk = li.inv_item_sk
WHERE i.i_class = 'newborn'
  AND cc.cc_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
  AND li.inv_quantity_on_hand > 800
GROUP BY
        i.i_item_id,
        i.i_product_name,
        cc.cc_name,
        cp.cp_catalog_page_number,
        td.t_hour,
        li.inv_quantity_on_hand,
        i.i_brand,
        cs.cs_order_number
ORDER BY total_profit DESC
LIMIT 100
