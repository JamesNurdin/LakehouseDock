WITH profit_by_cc AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_state AS state,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
        CASE WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) ELSE 0 END AS net_profit_margin
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND p.p_discount_active = 'Y'
    GROUP BY cc.cc_name, cc.cc_state, p.p_promo_name
    HAVING SUM(cs.cs_net_paid) > 100000
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY state ORDER BY net_profit_margin DESC) AS rank_in_state
    FROM profit_by_cc
)
SELECT
    call_center_name,
    state,
    promo_name,
    total_net_paid,
    total_net_profit,
    avg_discount_amount,
    net_profit_margin,
    rank_in_state
FROM ranked
WHERE rank_in_state <= 3
ORDER BY net_profit_margin DESC
