WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451796 AND 2452167
      AND cs.cs_ship_mode_sk IN (
          SELECT sm.sm_ship_mode_sk
          FROM ship_mode sm
          WHERE sm.sm_carrier = 'UPS'
      )
    GROUP BY
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number
)
SELECT
    i.i_item_id,
    w.w_warehouse_name,
    SUM(sa.total_sales) AS total_sales,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_qty
FROM sales_agg sa
JOIN item i
    ON i.i_item_sk = sa.cs_item_sk
JOIN customer c
    ON c.c_customer_sk = sa.cs_bill_customer_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = sa.cs_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = sa.cs_warehouse_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = sa.cs_item_sk
   AND inv.inv_warehouse_sk = sa.cs_warehouse_sk
   AND inv.inv_quantity_on_hand > 0
JOIN catalog_returns cr
    ON cr.cr_order_number = sa.cs_order_number
   AND cr.cr_item_sk = sa.cs_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = sa.cs_item_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_return_amt > 100
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE i.i_brand_id = 123
  AND w.w_state = 'CA'
GROUP BY
    i.i_item_id,
    w.w_warehouse_name
ORDER BY total_sales DESC
LIMIT 100
