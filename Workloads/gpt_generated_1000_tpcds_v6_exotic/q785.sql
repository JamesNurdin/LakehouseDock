WITH filtered_cust AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_purchase_estimate
    FROM tpcds.customer_demographics
    WHERE cd_purchase_estimate > 3000
)
SELECT * FROM (
    SELECT
        'catalog' AS channel,
        cp.cp_department AS segment,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_quantity) > 1000 THEN 'HIGH' ELSE 'LOW' END AS volume_level
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN filtered_cust cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cp.cp_department,
             cd.cd_gender,
             hd.hd_buy_potential
    UNION ALL
    SELECT
        'web' AS channel,
        'N/A' AS segment,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_quantity) > 800 THEN 'HIGH' ELSE 'LOW' END AS volume_level
    FROM tpcds.web_sales ws
    JOIN filtered_cust cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cd.cd_gender,
             hd.hd_buy_potential
) AS combined
ORDER BY channel,
         total_profit DESC
LIMIT 100
