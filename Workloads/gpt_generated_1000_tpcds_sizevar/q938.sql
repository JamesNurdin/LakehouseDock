WITH cs_agg AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_warehouse_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        SUM(cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(*) AS cnt_sales
    FROM catalog_sales
    WHERE cs_net_paid_inc_tax > 100
    GROUP BY cs_order_number, cs_item_sk, cs_warehouse_sk, cs_bill_cdemo_sk, cs_ship_cdemo_sk
),
unioned AS (
    SELECT
        w_ret.w_warehouse_name               AS warehouse_name,
        cd_refund.cd_gender                  AS gender,
        cs.total_net_paid_inc_tax            AS net_paid,
        CASE WHEN cs.total_net_paid_inc_tax > 1000 THEN 'HIGH' ELSE 'LOW' END AS net_category,
        (SELECT SUM(inv_quantity_on_hand)
         FROM inventory inv_sub
         WHERE inv_sub.inv_warehouse_sk = w_ret.w_warehouse_sk) AS inventory_qty
    FROM cs_agg cs
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN customer_demographics cd_refund
      ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_returning
      ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN warehouse w_ret
      ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN warehouse w_cs
      ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN inventory inv
      ON inv.inv_warehouse_sk = w_cs.w_warehouse_sk
    JOIN warehouse w_extra
      ON cr.cr_warehouse_sk = w_extra.w_warehouse_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_item_sk = cs.cs_item_sk
    )

    UNION DISTINCT

    SELECT
        w_ret2.w_warehouse_name,
        cd_refund2.cd_gender,
        cs2.total_net_paid_inc_tax,
        CASE WHEN cs2.total_net_paid_inc_tax > 1000 THEN 'HIGH' ELSE 'LOW' END,
        (SELECT SUM(inv_quantity_on_hand)
         FROM inventory inv_sub2
         WHERE inv_sub2.inv_warehouse_sk = w_ret2.w_warehouse_sk)
    FROM cs_agg cs2
    JOIN catalog_returns cr2
      ON cs2.cs_order_number = cr2.cr_order_number
     AND cs2.cs_item_sk = cr2.cr_item_sk
    JOIN customer_demographics cd_refund2
      ON cr2.cr_refunded_cdemo_sk = cd_refund2.cd_demo_sk
    JOIN customer_demographics cd_returning2
      ON cr2.cr_returning_cdemo_sk = cd_returning2.cd_demo_sk
    JOIN warehouse w_ret2
      ON cr2.cr_warehouse_sk = w_ret2.w_warehouse_sk
    JOIN customer_demographics cd_bill2
      ON cs2.cs_bill_cdemo_sk = cd_bill2.cd_demo_sk
    JOIN customer_demographics cd_ship2
      ON cs2.cs_ship_cdemo_sk = cd_ship2.cd_demo_sk
    JOIN warehouse w_cs2
      ON cs2.cs_warehouse_sk = w_cs2.w_warehouse_sk
    JOIN inventory inv2
      ON inv2.inv_warehouse_sk = w_cs2.w_warehouse_sk
    JOIN warehouse w_extra2
      ON cr2.cr_warehouse_sk = w_extra2.w_warehouse_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns crx
        WHERE crx.cr_order_number = cs2.cs_order_number
          AND crx.cr_item_sk = cs2.cs_item_sk
    )
)
SELECT
    warehouse_name,
    gender,
    SUM(net_paid)                         AS total_net_paid,
    CASE WHEN SUM(net_paid) > 5000 THEN 'VERY HIGH' ELSE 'NORMAL' END AS overall_category,
    MIN(inventory_qty)                    AS inventory_quantity
FROM unioned
GROUP BY GROUPING SETS (
    (warehouse_name, gender),
    (warehouse_name),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
