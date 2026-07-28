WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
),
base AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_return_amount,
        d.d_year,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cd.cd_education_status,
        s.s_store_id,
        ia.total_qty
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg ia
      ON w.w_warehouse_sk = ia.inv_warehouse_sk
     AND d.d_date_sk = ia.inv_date_sk
    JOIN customer cust
      ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND cd.cd_education_status = 'College'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
            AND cr2.cr_returned_date_sk = d.d_date_sk
            AND cr2.cr_return_quantity = 0
      )
),
agg AS (
    SELECT
        cr_warehouse_sk,
        w_warehouse_id,
        w_city,
        d_year,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(total_qty) AS total_inventory_qty,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        CASE
            WHEN SUM(cr_return_quantity) > 100 THEN 'HIGH_VOL'
            ELSE 'NORMAL_VOL'
        END AS volume_category,
        (SELECT MAX(cr_return_amount)
         FROM catalog_returns cr3
         WHERE cr3.cr_warehouse_sk = cr_warehouse_sk) AS max_return_amount
    FROM base
    GROUP BY cr_warehouse_sk, w_warehouse_id, w_city, d_year
)
SELECT
    w_warehouse_id,
    w_city,
    d_year,
    total_net_loss,
    total_return_qty,
    total_inventory_qty,
    distinct_orders,
    volume_category,
    max_return_amount,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC, loss_rank
LIMIT 100
