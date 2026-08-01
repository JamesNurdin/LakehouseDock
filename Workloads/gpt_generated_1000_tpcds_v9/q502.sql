SELECT DISTINCT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid_inc_ship_tax
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_list_price >= 205.00
  AND cs.cs_ship_hdemo_sk = 848
  AND w.w_zip = '56098'
LIMIT 100
