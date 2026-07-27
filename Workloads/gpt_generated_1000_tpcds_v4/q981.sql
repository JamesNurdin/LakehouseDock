WITH sales_hh AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_net_profit,
        ws.ws_ext_wholesale_cost,
        ws.ws_web_site_sk,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM tpcds.household_demographics hd
    JOIN tpcds.web_sales ws
        ON hd.hd_demo_sk = ws.ws_bill_hdemo_sk
    WHERE hd.hd_income_band_sk = 14
      AND hd.hd_vehicle_count >= 1
      AND ws.ws_net_paid_inc_ship > 1000
      AND ws.ws_ext_wholesale_cost < 3000
)
SELECT
    ws_site.web_name,
    ws_site.web_zip,
    sales_hh.hd_buy_potential,
    COUNT(DISTINCT sales_hh.ws_order_number) AS order_cnt,
    SUM(sales_hh.ws_net_paid_inc_ship) AS total_sales,
    AVG(sales_hh.ws_net_profit) AS avg_profit,
    MIN(sales_hh.ws_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(sales_hh.ws_ext_wholesale_cost) AS max_wholesale_cost
FROM sales_hh
JOIN tpcds.web_site ws_site
    ON sales_hh.ws_web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_zip = '46060'
GROUP BY ws_site.web_name, ws_site.web_zip, sales_hh.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
