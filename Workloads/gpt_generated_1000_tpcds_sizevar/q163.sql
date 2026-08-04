WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    cc.cc_name,
    t_sold.t_meal_time,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(cs.cs_net_profit) AS avg_profit,
    SUM(inv_agg.total_qty_on_hand) AS total_inventory_qty
FROM catalog_sales cs
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN time_dim t_ret
  ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN inv_agg
  ON inv_agg.inv_item_sk = i.i_item_sk
 AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE t_sold.t_meal_time = 'dinner'
  AND cd.cd_credit_rating = 'Good'
  AND w.w_state = 'CA'
  AND cs.cs_quantity > 5
  AND cs.cs_net_paid > (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 2450669
    )
GROUP BY w.w_warehouse_name, cc.cc_name, t_sold.t_meal_time
ORDER BY total_sales DESC
