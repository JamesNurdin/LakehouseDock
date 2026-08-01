WITH sales_returns AS (
   SELECT
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_net_loss,
      w_sales.w_warehouse_sk,
      w_sales.w_city,
      inv.inv_quantity_on_hand,
      ARRAY[cs.cs_quantity, cr.cr_return_quantity] AS qty_array
   FROM catalog_sales cs
   JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN warehouse w_sales ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
   LEFT JOIN catalog_returns cr
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN warehouse w_return ON cr.cr_warehouse_sk = w_return.w_warehouse_sk
   LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w_sales.w_warehouse_sk
   LEFT JOIN customer cust_returning ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
   LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
   LEFT JOIN customer cust_refunded ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
   LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
)
SELECT
   final.w_warehouse_sk,
   final.w_city,
   final.item_sk,
   final.total_sold_qty,
   final.total_sales_amount,
   final.total_net_profit,
   final.total_inventory_on_hand,
   final.qty_unrolled
FROM (
   SELECT
      sr.w_warehouse_sk,
      sr.w_city,
      sr.cs_item_sk AS item_sk,
      SUM(sr.cs_quantity) AS total_sold_qty,
      SUM(sr.cs_ext_sales_price) AS total_sales_amount,
      SUM(sr.cs_net_profit) AS total_net_profit,
      SUM(sr.inv_quantity_on_hand) AS total_inventory_on_hand,
      qty_element AS qty_unrolled
   FROM sales_returns sr
   LEFT JOIN UNNEST(sr.qty_array) AS t(qty_element) ON true
   WHERE sr.cr_return_quantity IS NULL
   GROUP BY sr.w_warehouse_sk, sr.w_city, sr.cs_item_sk, qty_element
   HAVING SUM(sr.cs_quantity) > 0

   UNION ALL

   SELECT
      sr.w_warehouse_sk,
      sr.w_city,
      sr.cs_item_sk AS item_sk,
      -SUM(sr.cr_return_quantity) AS total_sold_qty,
      -SUM(sr.cr_return_amount) AS total_sales_amount,
      -SUM(sr.cr_net_loss) AS total_net_profit,
      SUM(sr.inv_quantity_on_hand) AS total_inventory_on_hand,
      qty_element AS qty_unrolled
   FROM sales_returns sr
   LEFT JOIN UNNEST(sr.qty_array) AS t(qty_element) ON true
   WHERE sr.cr_return_quantity IS NOT NULL
   GROUP BY sr.w_warehouse_sk, sr.w_city, sr.cs_item_sk, qty_element
   HAVING SUM(sr.cr_return_quantity) > 0
) AS final
WHERE EXISTS (SELECT 1 FROM customer c WHERE c.c_preferred_cust_flag = 'Y')
ORDER BY final.total_sales_amount DESC, final.w_city
OFFSET 10 LIMIT 100
