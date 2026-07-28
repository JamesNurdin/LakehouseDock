WITH catalog_profit AS (
    SELECT
        'Catalog' AS source,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_department = 'Jewelry'
      AND hd.hd_income_band_sk = 10
    GROUP BY sm.sm_type
),
web_profit AS (
    SELECT
        'Web' AS source,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE w.web_city = 'Mount Olive'
      AND hd.hd_income_band_sk = 10
    GROUP BY sm.sm_type
)
SELECT source,
       ship_mode_type,
       total_net_profit
FROM catalog_profit
UNION ALL
SELECT source,
       ship_mode_type,
       total_net_profit
FROM web_profit
ORDER BY source, ship_mode_type
