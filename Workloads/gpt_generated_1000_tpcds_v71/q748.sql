/*
  Goal: Compare aggregated sales and return performance by item category across the catalog and store channels, 
  enriching the results with warehouse inventory and applying extensive filters. The query demonstrates
  multi‑CTE aggregation, a UNION ALL set operation, a window function, and a final LIMIT.
*/
WITH cat_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        cc.cc_name AS segment,
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc AS reason_desc,
        SUM(cs.cs_net_paid) AS amount,
        SUM(cs.cs_quantity) AS quantity,
        CAST('catalog_sales' AS varchar) AS src,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_paid) DESC) AS cat_rank
    FROM catalog_sales cs
    JOIN item i                ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td           ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca   ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cc.cc_state = 'TX'                         AND
        w.w_state = 'CA'                           AND
        i.i_current_price > 50                     AND
        td.t_hour BETWEEN 9 AND 17                AND
        cd.cd_gender = 'M'                         AND
        ca.ca_location_type = 'single family'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        cc.cc_name,
        w.w_warehouse_name,
        sm.sm_type,
        r.r_reason_desc
),
store_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        s.s_store_name AS segment,
        CAST(NULL AS varchar) AS warehouse_name,
        CAST(NULL AS varchar) AS ship_mode_type,
        r.r_reason_desc AS reason_desc,
        SUM(ss.ss_net_paid) AS amount,
        SUM(ss.ss_quantity) AS quantity,
        CAST('store_sales' AS varchar) AS src,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_net_paid) DESC) AS cat_rank
    FROM store_sales ss
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td           ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        s.s_state = 'WA'                     AND
        td.t_hour BETWEEN 10 AND 20          AND
        cd.cd_marital_status = 'M'           AND
        ca.ca_location_type = 'condo'        AND
        i.i_color = 'Red'                    AND
        ss.ss_sales_price > 20
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        s.s_store_name,
        r.r_reason_desc
),
union_data AS (
    SELECT * FROM cat_data
    UNION ALL
    SELECT * FROM store_data
)
SELECT
    ud.i_item_id,
    ud.i_category,
    ud.segment,
    COALESCE(ud.warehouse_name, w2.w_warehouse_name) AS warehouse_name,
    ud.amount,
    ud.quantity,
    inv.inv_quantity_on_hand,
    ud.src,
    ud.cat_rank,
    SUM(ud.amount) OVER (PARTITION BY ud.segment) AS seg_total_amount
FROM union_data ud
JOIN inventory inv          ON inv.inv_item_sk = ud.i_item_sk
LEFT JOIN warehouse w2      ON inv.inv_warehouse_sk = w2.w_warehouse_sk
WHERE inv.inv_quantity_on_hand > 0
ORDER BY seg_total_amount DESC, ud.amount DESC
LIMIT 100
