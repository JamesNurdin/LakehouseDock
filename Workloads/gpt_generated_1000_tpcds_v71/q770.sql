WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
    GROUP BY cs.cs_warehouse_sk, cs.cs_promo_sk, cs.cs_item_sk
)
SELECT
    w.w_warehouse_name,
    p.p_promo_name,
    cd.cd_gender,
    sa.total_net_paid,
    sa.total_quantity,
    CASE
        WHEN sa.total_quantity > 100 THEN 'HIGH'
        ELSE 'LOW'
    END AS qty_category,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY sa.total_net_paid DESC) AS rn
FROM sales_agg sa
JOIN catalog_sales cs
    ON cs.cs_warehouse_sk = sa.cs_warehouse_sk
   AND cs.cs_promo_sk = sa.cs_promo_sk
   AND cs.cs_item_sk = sa.cs_item_sk
JOIN warehouse w
    ON w.w_warehouse_sk = sa.cs_warehouse_sk
JOIN promotion p
    ON p.p_promo_sk = sa.cs_promo_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
    ON t.t_time_sk = cs.cs_sold_time_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE p.p_discount_active = 'Y'
  AND inv.inv_quantity_on_hand > 0
  AND cd.cd_marital_status = 'M'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = sa.cs_item_sk
          AND cr.cr_order_number = cs.cs_order_number
    )
ORDER BY sa.total_net_paid DESC
LIMIT 100
