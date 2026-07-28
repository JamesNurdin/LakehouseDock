SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    cs.cs_net_paid_inc_ship,
    inv.inv_quantity_on_hand,
    ws.web_name,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
    ) AS total_return_amount,
    RANK() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_paid_inc_ship DESC) AS sales_rank_year
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN call_center cc
  ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN date_dim d
  ON d.d_date_sk = cs.cs_sold_date_sk
JOIN time_dim t
  ON t.t_time_sk = cs.cs_sold_time_sk
JOIN customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
  AND inv.inv_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND i.i_current_price > 50
  AND w.w_state = 'CA'
  AND cc.cc_employees >= 200
  AND ws.web_tax_percentage < 5.0
ORDER BY sales_rank_year
LIMIT 100
