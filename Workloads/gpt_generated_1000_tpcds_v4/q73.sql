WITH store_agg AS (
    SELECT
        hd.hd_buy_potential AS buy_potential,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_ext_tax > 10.00
      AND hd.hd_buy_potential IN ('0-500', '1001-5000')
    GROUP BY hd.hd_buy_potential
),
web_agg AS (
    SELECT
        hd.hd_buy_potential AS buy_potential,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
        COUNT(*) AS txn_count
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_coupon_amt > 100.00
      AND hd.hd_buy_potential IN ('0-500', '1001-5000')
    GROUP BY hd.hd_buy_potential
)
SELECT
    buy_potential,
    channel,
    total_net_profit,
    avg_discount_amt,
    txn_count
FROM store_agg
UNION ALL
SELECT
    buy_potential,
    channel,
    total_net_profit,
    avg_discount_amt,
    txn_count
FROM web_agg
ORDER BY buy_potential, channel
LIMIT 100
