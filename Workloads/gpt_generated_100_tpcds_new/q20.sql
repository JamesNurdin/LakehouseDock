WITH store_agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_holiday AS d_holiday,
        hd.hd_buy_potential AS hd_buy_potential,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND ss.ss_ext_sales_price > 1000
    GROUP BY CUBE (d.d_year, d.d_holiday, hd.hd_buy_potential)
),
web_agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_holiday AS d_holiday,
        hd.hd_buy_potential AS hd_buy_potential,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND ws.ws_ext_discount_amt > 500
    GROUP BY CUBE (d.d_year, d.d_holiday, hd.hd_buy_potential)
)
SELECT
    d_year,
    d_holiday,
    hd_buy_potential,
    channel,
    total_net_profit,
    txn_count
FROM (
    SELECT d_year, d_holiday, hd_buy_potential, channel, total_net_profit, txn_count FROM store_agg
    UNION ALL
    SELECT d_year, d_holiday, hd_buy_potential, channel, total_net_profit, txn_count FROM web_agg
) AS combined
ORDER BY d_year NULLS LAST,
         d_holiday,
         hd_buy_potential,
         channel
LIMIT 100
