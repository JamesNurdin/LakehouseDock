WITH catalog_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_coupon_amt > 500
      AND hd.hd_vehicle_count >= 0
    GROUP BY hd.hd_demo_sk, hd.hd_dep_count
),
web_agg AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_dep_count,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ext_list_price > 2000
      AND hd.hd_vehicle_count >= 0
    GROUP BY hd.hd_demo_sk, hd.hd_dep_count
)
SELECT
    demo_sk,
    dep_count,
    total_net_profit,
    total_quantity,
    source
FROM (
    SELECT
        hd_demo_sk AS demo_sk,
        hd_dep_count AS dep_count,
        catalog_net_profit AS total_net_profit,
        catalog_quantity AS total_quantity,
        'catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT
        hd_demo_sk AS demo_sk,
        hd_dep_count AS dep_count,
        web_net_profit AS total_net_profit,
        web_quantity AS total_quantity,
        'web' AS source
    FROM web_agg
) combined
ORDER BY demo_sk, source
