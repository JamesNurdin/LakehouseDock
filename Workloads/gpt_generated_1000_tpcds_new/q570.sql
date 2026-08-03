WITH call_center_stats AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state IN ('MN', 'GA')
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_channel_tv = 'Y'
      )
    GROUP BY cc.cc_call_center_sk, cc.cc_state
),
warehouse_stats AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        (
            SELECT AVG(cs2.cs_ext_discount_amt)
            FROM catalog_sales cs2
            WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
        ) AS avg_discount
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state IN ('GA', 'NC')
    GROUP BY w.w_warehouse_sk, w.w_state
),
full_join AS (
    SELECT
        COALESCE(cc.cc_call_center_sk, -1) AS cc_sk,
        cc.cc_state,
        COALESCE(w.w_warehouse_sk, -1) AS wh_sk,
        w.w_state,
        COALESCE(cc.total_net_paid, 0) AS cc_total_net_paid,
        COALESCE(w.total_net_paid, 0) AS wh_total_net_paid
    FROM call_center_stats cc
    FULL OUTER JOIN warehouse_stats w
        ON cc.cc_state = w.w_state
),
promo_key_set AS (
    SELECT cs.cs_call_center_sk AS id,
           SUM(cs.cs_net_paid) AS amount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY cs.cs_call_center_sk
    UNION ALL
    SELECT cs.cs_warehouse_sk AS id,
           SUM(cs.cs_net_paid) AS amount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY cs.cs_warehouse_sk
)
SELECT id, amount
FROM (
    SELECT cc_sk AS id, cc_total_net_paid AS amount
    FROM full_join
    WHERE cc_total_net_paid > 0
    UNION
    SELECT wh_sk AS id, wh_total_net_paid AS amount
    FROM full_join
    WHERE wh_total_net_paid > 0
) AS union_set
EXCEPT
SELECT id, amount
FROM promo_key_set
LIMIT 100
