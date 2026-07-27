SELECT
    hd_buy_potential,
    total_return_amt,
    avg_return_tax,
    loss_category,
    CASE WHEN total_return_amt > 5000 THEN 'Big' ELSE 'Small' END AS size_category
FROM (
    SELECT
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        CASE
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High Loss'
            WHEN SUM(sr.sr_net_loss) BETWEEN 1000 AND 10000 THEN 'Medium Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM store_returns sr
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '>10000'
      AND hd.hd_vehicle_count >= 2
      AND sr.sr_return_tax > 0
    GROUP BY hd.hd_buy_potential
) a
UNION ALL
SELECT
    hd_buy_potential,
    total_return_amt,
    avg_return_tax,
    loss_category,
    CASE WHEN total_return_amt > 5000 THEN 'Big' ELSE 'Small' END AS size_category
FROM (
    SELECT
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        CASE
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High Loss'
            WHEN SUM(sr.sr_net_loss) BETWEEN 1000 AND 10000 THEN 'Medium Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM store_returns sr
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '0-500'
      AND hd.hd_dep_count <= 3
      AND sr.sr_return_tax > 0
    GROUP BY hd.hd_buy_potential
) b
LIMIT 100
