WITH ss_agg AS (
    SELECT
        s.s_store_id,
        hd.hd_buy_potential,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_city = 'Washington'
      AND hd.hd_vehicle_count >= 0
    GROUP BY s.s_store_id, hd.hd_buy_potential
    HAVING SUM(ss.ss_net_profit) > (
        SELECT AVG(cs.cs_net_profit) FROM catalog_sales cs
    )
),
ss_ranked AS (
    SELECT
        s_store_id,
        hd_buy_potential,
        total_net_profit,
        txn_count,
        RANK() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS profit_rank
    FROM ss_agg
),
cs_agg AS (
    SELECT
        hd.hd_buy_potential,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_ext_tax > 50
      AND hd.hd_buy_potential IN ('>10000', '5001-10000')
    GROUP BY hd.hd_buy_potential
    HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2
    )
)
SELECT
    s_store_id AS entity_id,
    hd_buy_potential,
    total_net_profit,
    txn_count,
    profit_rank
FROM ss_ranked
UNION ALL
SELECT
    'CATALOG' AS entity_id,
    hd_buy_potential,
    total_net_profit,
    txn_count,
    NULL AS profit_rank
FROM cs_agg
ORDER BY total_net_profit DESC
LIMIT 100
