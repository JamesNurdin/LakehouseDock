/* goal: Analyze average combined catalog and store return losses per store for the year 1998, focusing on damaged‑item returns in California stores and high inventory periods. */
WITH base AS (
    SELECT
        cr.cr_order_number               AS order_number,
        d.d_year                         AS year,
        s.s_store_name                   AS store_name,
        s.s_state                        AS store_state,
        r_cr.r_reason_desc               AS reason_desc,
        cr.cr_net_loss                   AS catalog_net_loss,
        sr.sr_net_loss                   AS store_net_loss,
        COALESCE(sr.sr_net_loss, 0)      AS store_net_loss_coalesced,
        inv.inv_quantity_on_hand        AS inventory_on_hand,
        cd_cr.cd_gender                  AS returning_gender,
        cd_sr.cd_gender                  AS store_customer_gender,
        cr.cr_return_amount              AS return_amount,
        cr.cr_return_quantity            AS return_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_reason_sk = r_cr.r_reason_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_demographics cd_cr
        ON cr.cr_returning_cdemo_sk = cd_cr.cd_demo_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND t.t_hour BETWEEN 8 AND 20
      AND r_cr.r_reason_desc LIKE '%damaged%'
      AND inv.inv_quantity_on_hand > 500
      AND s.s_state = 'CA'
      AND cd_cr.cd_gender = 'M'
      AND cr.cr_return_amount > 100
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_date_sk = d.d_date_sk
            AND inv2.inv_quantity_on_hand > 800
      )
),
agg AS (
    SELECT
        store_name,
        reason_desc,
        SUM(catalog_net_loss)            AS total_catalog_loss,
        SUM(store_net_loss_coalesced)    AS total_store_loss,
        AVG(inventory_on_hand)           AS avg_inventory_on_hand,
        COUNT(*)                         AS return_cnt
    FROM base
    GROUP BY store_name, reason_desc
)
SELECT
    store_name,
    AVG(total_catalog_loss + total_store_loss) AS avg_total_loss_per_reason,
    SUM(return_cnt)                            AS total_returns,
    AVG(avg_inventory_on_hand)                AS avg_inventory_across_reasons
FROM agg
WHERE total_catalog_loss > 200
GROUP BY store_name
HAVING SUM(return_cnt) > 5
ORDER BY avg_total_loss_per_reason DESC
LIMIT 100
