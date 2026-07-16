WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cs.cs_call_center_sk, cs.cs_ship_mode_sk
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk AS call_center_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cr.cr_call_center_sk, cr.cr_ship_mode_sk
)
SELECT
    cc.cc_state,
    sm.sm_type,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_margin,
    RANK() OVER (ORDER BY COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.call_center_sk = r.call_center_sk
    AND s.ship_mode_sk = r.ship_mode_sk
LEFT JOIN call_center cc
    ON COALESCE(s.call_center_sk, r.call_center_sk) = cc.cc_call_center_sk
LEFT JOIN ship_mode sm
    ON COALESCE(s.ship_mode_sk, r.ship_mode_sk) = sm.sm_ship_mode_sk
WHERE cc.cc_state IN ('TN', 'GA', 'MI')
  AND cc.cc_class = 'large'
ORDER BY net_margin DESC
LIMIT 50
