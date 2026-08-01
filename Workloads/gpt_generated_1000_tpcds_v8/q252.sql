WITH inventory_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        inv.inv_date_sk,
        inv.inv_quantity_on_hand
    FROM warehouse w
    FULL OUTER JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
)
SELECT purchase_set.c_customer_id
FROM (
    SELECT DISTINCT c.c_customer_id
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ss.ss_net_profit > 0
      AND EXISTS (
          SELECT 1
          FROM inventory_warehouse iw
          WHERE iw.w_warehouse_name = 'WH1'
            AND iw.inv_quantity_on_hand > 0
      )
) AS purchase_set
EXCEPT
SELECT DISTINCT c.c_customer_id
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer c
    ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND wr.wr_net_loss > 0
