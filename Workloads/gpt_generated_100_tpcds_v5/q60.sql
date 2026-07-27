WITH joined_data AS (
    SELECT
        cc.cc_name,
        cc.cc_division_name,
        w.w_state,
        w.w_warehouse_name,
        r.r_reason_desc,
        hd.hd_income_band_sk,
        cs.cs_order_number,
        cs.cs_net_profit AS catalog_net_profit,
        cr.cr_net_loss,
        ws.ws_order_number,
        ws.ws_net_profit AS web_net_profit,
        wsit.web_name
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
     AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cc.cc_class = 'Technology'
      AND w.w_state = 'GA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wsit.web_class = 'A'
      AND cc.cc_gmt_offset >= -5
),
agg AS (
    SELECT
        cc_name,
        w_state,
        SUM(total_profit) AS total_profit
    FROM (
        SELECT
            cc_name,
            w_state,
            (catalog_net_profit + web_net_profit - cr_net_loss) AS total_profit
        FROM joined_data
    ) sub
    GROUP BY GROUPING SETS (
        (cc_name, w_state),
        (cc_name),
        (w_state),
        ()
    )
)
SELECT
    cc_name,
    w_state,
    total_profit,
    CASE WHEN total_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    CASE
        WHEN cc_name IS NOT NULL AND w_state IS NOT NULL
        THEN RANK() OVER (PARTITION BY w_state ORDER BY total_profit DESC)
    END AS profit_rank_state
FROM agg
ORDER BY total_profit DESC
LIMIT 100
