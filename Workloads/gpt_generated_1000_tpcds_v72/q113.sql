WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id               AS cc_call_center_id,
        cd.cd_gender                       AS cd_gender,
        sm.sm_carrier                      AS sm_carrier,
        p.p_promo_name                     AS p_promo_name,
        p.p_promo_sk                       AS p_promo_sk,
        SUM(cs.cs_ext_sales_price)        AS total_sales,
        SUM(cs.cs_net_profit)             AS total_profit,
        COUNT(*)                           AS order_cnt,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE'
            ELSE 'NON_POSITIVE'
        END                               AS profit_flag
    FROM
        catalog_sales cs
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        CROSS JOIN LATERAL (
            SELECT sm.sm_carrier, sm.sm_code
            FROM ship_mode sm
            WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
              AND sm.sm_code = 'AIR'
        ) sm
    WHERE
        cs.cs_wholesale_cost > 50
        AND cs.cs_net_paid_inc_tax BETWEEN 1000 AND 6000
        AND cc.cc_state = 'CA'
        AND p.p_end_date_sk > 2450300
    GROUP BY
        cc.cc_call_center_id,
        cd.cd_gender,
        sm.sm_carrier,
        p.p_promo_name,
        p.p_promo_sk
)
SELECT
    sa.cc_call_center_id,
    sa.cd_gender,
    sa.sm_carrier,
    sa.p_promo_name,
    sa.total_sales,
    sa.total_profit,
    sa.order_cnt,
    sa.profit_flag,
    ROUND(sa.total_sales / NULLIF(sa.order_cnt, 0), 2) AS avg_sales_per_order
FROM
    sales_agg sa
WHERE
    NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = sa.p_promo_sk
          AND p2.p_channel_press = 'N'
    )
    AND sa.total_sales > 5000
ORDER BY
    sa.total_sales DESC
LIMIT 100
