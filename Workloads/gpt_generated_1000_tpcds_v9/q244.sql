WITH joined_data AS (
    SELECT
        i.i_category,
        st.s_store_name,
        sm.sm_carrier,
        ss.ss_net_profit,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        cc.cc_state,
        cs.cs_sales_price,
        i.i_current_price,
        st.s_state,
        hd.hd_dep_count
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
       AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_state = 'CA'
      AND cs.cs_sales_price > 100.00
      AND i.i_current_price BETWEEN 20.00 AND 200.00
      AND st.s_state = 'TX'
      AND sm.sm_carrier IN ('USPS', 'MSC')
      AND hd.hd_dep_count >= 2
),
aggregated AS (
    SELECT
        i_category,
        s_store_name,
        sm_carrier,
        SUM(ss_net_profit) AS sum_store_sales_profit,
        SUM(cs_net_profit) AS sum_catalog_sales_profit,
        SUM(ws_net_profit) AS sum_web_sales_profit,
        SUM(sr_net_loss) AS sum_store_returns_loss,
        COUNT(*) AS trans_cnt
    FROM joined_data
    GROUP BY GROUPING SETS (
        (i_category, s_store_name, sm_carrier),
        (i_category, sm_carrier),
        (s_store_name, sm_carrier),
        (sm_carrier),
        ()
    )
)
SELECT
    i_category,
    s_store_name,
    sm_carrier,
    sum_store_sales_profit,
    sum_catalog_sales_profit,
    sum_web_sales_profit,
    sum_store_returns_loss,
    trans_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY sum_store_sales_profit DESC) AS rn_by_category
FROM aggregated
WHERE i_category IS NOT NULL
  AND s_store_name NOT IN (
        SELECT s_store_name
        FROM store
        WHERE s_state = 'FL'
    )
ORDER BY i_category ASC, rn_by_category ASC
LIMIT 100
