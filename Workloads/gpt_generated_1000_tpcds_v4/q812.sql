WITH billed AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_wholesale_cost > 20.00
      AND hd.hd_dep_count <= 5
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential
),
shipped AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_wholesale_cost > 20.00
      AND hd.hd_dep_count <= 5
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential
)
SELECT
    source,
    hd_demo_sk,
    hd_buy_potential,
    total_profit,
    order_cnt,
    RANK() OVER (PARTITION BY source ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT 'BILL' AS source, hd_demo_sk, hd_buy_potential, total_profit, order_cnt
    FROM billed
    UNION ALL
    SELECT 'SHIP' AS source, hd_demo_sk, hd_buy_potential, total_profit, order_cnt
    FROM shipped
) AS combined
ORDER BY source, profit_rank
LIMIT 100
