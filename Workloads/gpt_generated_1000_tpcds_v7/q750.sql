WITH base_join AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        cc.cc_name,
        cc.cc_state AS cc_state,
        sm.sm_type,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_paid AS store_net_paid,
        ca.ca_state AS ca_state,
        cd.cd_education_status,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND ca.ca_state = 'CA'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 100
      AND cs.cs_quantity > 1
),
agg_item AS (
    SELECT
        i_item_id,
        i_category,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(cs_net_paid) DESC) AS rn_category
    FROM base_join
    GROUP BY i_item_id, i_category
)
SELECT
    i_category,
    AVG(total_net_paid) AS avg_net_paid_per_item,
    SUM(total_return_amount) AS total_return_amount_per_category,
    COUNT(*) AS top_items_cnt
FROM agg_item
WHERE rn_category <= 3
GROUP BY i_category
HAVING AVG(total_net_paid) > 1000
ORDER BY avg_net_paid_per_item DESC
