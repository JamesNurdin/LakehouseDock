SELECT
    hd_demo_sk,
    hd_buy_potential,
    total_amount,
    transaction_cnt,
    source
FROM (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(ss.ss_sales_price) AS total_amount,
        COUNT(*) AS transaction_cnt,
        'store' AS source
    FROM store_sales ss
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '501-1000'
      AND ss.ss_sales_price > 30
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential

    UNION ALL

    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_amount,
        COUNT(*) AS transaction_cnt,
        'catalog' AS source
    FROM catalog_sales cs
    INNER JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '501-1000'
      AND cs.cs_net_paid_inc_ship_tax > 2000
    GROUP BY hd.hd_demo_sk, hd.hd_buy_potential
) AS combined
ORDER BY total_amount DESC
LIMIT 100
