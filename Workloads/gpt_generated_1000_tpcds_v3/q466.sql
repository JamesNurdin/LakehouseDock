WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        hd.hd_buy_potential AS buy_potential,
        COUNT(*) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_zip LIKE '9%'
      AND hd.hd_vehicle_count > 0
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND ws.ws_quantity >= 2
      AND ws.ws_bill_customer_sk IN (
          SELECT DISTINCT ws2.ws_bill_customer_sk
          FROM web_sales ws2
          WHERE ws2.ws_net_paid_inc_ship_tax > 1500
      )
    GROUP BY ca.ca_state, hd.hd_buy_potential
)
SELECT
    state,
    buy_potential,
    order_count,
    total_sales,
    total_net_paid,
    avg_profit,
    total_sales / (SELECT AVG(total_sales) FROM sales_agg) AS sales_vs_global_avg,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM household_demographics hd3
            WHERE hd3.hd_buy_potential = sales_agg.buy_potential
              AND hd3.hd_dep_count > 2
        ) THEN 'HighDep'
        ELSE 'LowDep'
    END AS dep_category
FROM sales_agg
WHERE order_count > 10
ORDER BY total_sales DESC
LIMIT 100
