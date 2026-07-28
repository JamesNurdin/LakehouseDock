WITH billed AS (
    SELECT
        hd.hd_buy_potential AS buy_potential,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential <> 'Unknown'
      AND ws.ws_ext_list_price > 5000
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
            AND ws2.ws_quantity > 5
      )
    GROUP BY hd.hd_buy_potential
),
shipped AS (
    SELECT
        hd.hd_buy_potential AS buy_potential,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (1, 4, 10)
      AND ws.ws_ext_sales_price BETWEEN 1000 AND 5000
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_ship_customer_sk = ws.ws_ship_customer_sk
            AND ws2.ws_quantity > 3
      )
    GROUP BY hd.hd_buy_potential
)
SELECT
    combined.buy_potential,
    combined.total_profit,
    combined.total_profit / (SELECT SUM(ws.ws_net_profit) FROM web_sales ws) AS profit_share
FROM (
    SELECT buy_potential, total_profit FROM billed
    UNION ALL
    SELECT buy_potential, total_profit FROM shipped
) AS combined
ORDER BY combined.total_profit DESC
LIMIT 100
