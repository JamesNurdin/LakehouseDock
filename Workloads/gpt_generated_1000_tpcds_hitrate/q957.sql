WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_order_number,
        c.c_customer_id,
        i.i_manufact,
        p.p_channel_catalog,
        r.r_reason_desc,
        sm.sm_type,
        wr.wr_return_quantity,
        wp.wp_type
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE p.p_channel_catalog = 'N'
      AND i.i_manufact = 'ableanti'
      AND r.r_reason_desc = 'Damaged'
),
unioned AS (
    SELECT
        cs_sold_date_sk,
        i_manufact,
        sm_type,
        cs_quantity,
        cs_net_paid,
        cs_order_number
    FROM base
    UNION DISTINCT
    SELECT
        cs_sold_date_sk,
        i_manufact,
        sm_type,
        cs_quantity,
        cs_net_paid,
        cs_order_number
    FROM base
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = base.cs_order_number
          AND cr2.cr_return_amount > 0
    )
)
SELECT
    COALESCE(cs_sold_date_sk, -1) AS sold_date_sk,
    i_manufact,
    sm_type,
    SUM(cs_net_paid) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(
        (SELECT COALESCE(SUM(cr_return_amount), 0)
         FROM catalog_returns cr
         WHERE cr.cr_returned_date_sk = unioned.cs_sold_date_sk)
    ) AS total_return_amount,
    CASE WHEN SUM(cs_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM unioned
GROUP BY ROLLUP (cs_sold_date_sk, i_manufact, sm_type)
ORDER BY cs_sold_date_sk, i_manufact, sm_type
LIMIT 100
