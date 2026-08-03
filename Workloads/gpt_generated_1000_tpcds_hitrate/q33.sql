WITH catalog_sales_anti AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        cs.cs_net_paid AS sales_amount,
        cc.cc_name AS channel_name
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_quantity > 5
      AND cc.cc_state = 'CA'
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
),
web_sales_anti AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        ws.ws_net_paid AS sales_amount,
        'Web' AS channel_name
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_quantity > 5
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
      )
)
SELECT
    demo_sk,
    channel_name,
    SUM(sales_amount) AS total_sales,
    COUNT(*) AS sales_cnt,
    GROUPING(demo_sk) AS grp_demo,
    GROUPING(channel_name) AS grp_channel
FROM (
    SELECT * FROM catalog_sales_anti
    UNION
    SELECT * FROM web_sales_anti
) u
GROUP BY GROUPING SETS (
    (demo_sk, channel_name),
    (demo_sk),
    (channel_name),
    ()
)
LIMIT 100
