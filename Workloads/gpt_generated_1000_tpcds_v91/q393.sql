WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_ext_ship_cost,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_item_desc,
        p.p_promo_id,
        p.p_cost,
        cc.cc_call_center_id,
        cc.cc_name,
        cp.cp_catalog_page_id,
        cp.cp_department,
        sm.sm_ship_mode_id,
        sm.sm_type,
        split(i.i_item_desc, ' ') AS item_desc_words
    FROM catalog_sales cs
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_ship_cost > 1000
      AND c.c_birth_month IN (4, 7, 10)
      AND p.p_cost = 1000.00
),
returns_base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        cr.cr_item_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
),
order_intersection AS (
    SELECT cs_order_number
    FROM sales_base
    WHERE cs_net_paid > 5000
    INTERSECT
    SELECT cr_order_number
    FROM returns_base
    WHERE cr_return_quantity > 2
),
sales_enhanced AS (
    SELECT
        sb.*,
        RANK() OVER (PARTITION BY sb.c_customer_sk ORDER BY sb.cs_net_paid DESC) AS purchase_rank,
        ROW_NUMBER() OVER (PARTITION BY sb.c_customer_sk ORDER BY sb.cs_sold_date_sk DESC) AS recent_purchase_seq,
        AVG(sb.cs_ext_ship_cost) OVER (PARTITION BY sb.c_customer_sk) AS avg_ship_cost_per_customer,
        CASE
            WHEN sb.cs_net_paid >= (SELECT MAX(cs_net_paid) FROM catalog_sales) THEN 'MAX_PAID'
            WHEN sb.cs_ext_ship_cost > AVG(sb.cs_ext_ship_cost) OVER (PARTITION BY sb.c_customer_sk) THEN 'ABOVE_AVG_SHIP'
            ELSE 'NORMAL'
        END AS payment_category
    FROM sales_base sb
    WHERE sb.cs_order_number IN (SELECT cs_order_number FROM order_intersection)
)
SELECT
    se.cs_order_number,
    se.c_customer_sk,
    se.c_first_name,
    se.c_last_name,
    se.c_birth_month,
    se.i_item_id,
    se.i_product_name,
    se.i_category,
    se.i_brand,
    se.cs_quantity,
    se.cs_net_paid,
    se.cs_ext_ship_cost,
    se.purchase_rank,
    se.recent_purchase_seq,
    se.avg_ship_cost_per_customer,
    se.payment_category,
    p.p_promo_id,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    word AS item_desc_word
FROM sales_enhanced se
INNER JOIN promotion p
    ON se.cs_promo_sk = p.p_promo_sk
INNER JOIN call_center cc
    ON se.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
    ON se.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm
    ON se.cs_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(se.item_desc_words) AS t(word)
WHERE se.cs_net_profit > 0
ORDER BY se.cs_net_paid DESC
LIMIT 100
