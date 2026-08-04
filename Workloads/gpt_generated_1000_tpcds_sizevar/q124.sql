WITH overall_avg AS (
    SELECT avg(cs_net_paid) AS avg_net_paid
    FROM catalog_sales
)
SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid_inc_ship) AS total_web_net_paid_inc_ship,
    CASE
        WHEN SUM(cs.cs_net_profit) > (SELECT avg_net_paid FROM overall_avg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk = 9
  AND hd.hd_vehicle_count >= 1
  AND cs.cs_list_price > 50
  AND ws.ws_list_price BETWEEN 30 AND 80
GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
HAVING SUM(cs.cs_net_paid) > 1000
UNION DISTINCT
SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid_inc_ship) AS total_web_net_paid_inc_ship,
    CASE
        WHEN SUM(cs.cs_net_profit) > (SELECT avg_net_paid FROM overall_avg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk = 9
  AND hd.hd_vehicle_count >= 1
  AND cs.cs_list_price > 50
  AND ws.ws_list_price BETWEEN 30 AND 80
GROUP BY hd.hd_demo_sk, hd.hd_income_band_sk, hd.hd_buy_potential
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_catalog_net_paid DESC
LIMIT 100
