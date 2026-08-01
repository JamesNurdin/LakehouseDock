WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_net_loss
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE cr.cr_return_ship_cost > 100
      AND cr.cr_return_amount > 50
      AND cr.cr_net_loss > 0
)
SELECT
    w.w_warehouse_name,
    w.w_county,
    SUM(sr.cs_net_paid) AS total_net_paid,
    SUM(sr.cr_return_amount) AS total_return_amount,
    SUM(sr.cr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT sr.cs_order_number) AS distinct_order_cnt
FROM sales_returns sr
JOIN warehouse w
    ON sr.cs_warehouse_sk = w.w_warehouse_sk
WHERE w.w_county = 'Bronx County'
  AND w.w_gmt_offset = -5.00
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_warehouse_sk = w.w_warehouse_sk
          AND i.inv_quantity_on_hand < 500
          AND i.inv_date_sk = 2451088
    )
GROUP BY ROLLUP (w.w_warehouse_name, w.w_county)
LIMIT 100
