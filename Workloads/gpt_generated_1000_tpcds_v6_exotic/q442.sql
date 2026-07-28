WITH base AS (
   SELECT 
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d_ret.d_year AS return_year,
        r.r_reason_desc,
        sm.sm_type AS ship_type,
        ca_ref.ca_state AS refunded_state,
        cd_ref.cd_credit_rating AS refunded_credit,
        c_ref.c_customer_id,
        inv.inv_quantity_on_hand,
        wp.wp_type AS web_page_type,
        wpc.d_year AS wp_creation_year
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   LEFT JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk
                         AND inv.inv_item_sk = cr.cr_item_sk
   LEFT JOIN web_page wp ON wp.wp_customer_sk = c_ref.c_customer_sk
   LEFT JOIN date_dim wpc ON wp.wp_creation_date_sk = wpc.d_date_sk
   WHERE d_ret.d_year = 2001
     AND EXISTS (
         SELECT 1
         FROM inventory inv2
         WHERE inv2.inv_item_sk = cr.cr_item_sk
           AND inv2.inv_quantity_on_hand > 500
     )
),
agg AS (
   SELECT
        return_year,
        r_reason_desc,
        ship_type,
        refunded_state,
        refunded_credit,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
   FROM base
   GROUP BY ROLLUP (return_year, r_reason_desc, ship_type, refunded_state, refunded_credit)
   HAVING SUM(cr_return_amount) > 1000
)
SELECT
    return_year,
    r_reason_desc,
    ship_type,
    refunded_state,
    refunded_credit,
    total_return_amount,
    total_net_loss,
    cnt_returns,
    avg_inventory_on_hand,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
