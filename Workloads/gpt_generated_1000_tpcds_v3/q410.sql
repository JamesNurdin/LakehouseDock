WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_hdemo_sk,
        wr.wr_web_page_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        CASE
            WHEN wr.wr_fee > 50 THEN 'High'
            WHEN wr.wr_fee > 20 THEN 'Medium'
            ELSE 'Low'
        END AS fee_category
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100.00
      AND wr.wr_fee > 20.00
      AND wr.wr_return_quantity >= 1
),
aggregated_returns AS (
    SELECT
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        fr.fee_category,
        COUNT(*) AS return_cnt,
        SUM(fr.wr_return_amt) AS total_return_amt,
        AVG(fr.wr_return_amt) AS avg_return_amt,
        SUM(fr.wr_fee) AS total_fee,
        MAX(fr.wr_return_ship_cost) AS max_ship_cost
    FROM filtered_returns fr
    JOIN household_demographics hd
        ON fr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = fr.wr_web_page_sk
          AND wp.wp_autogen_flag = 'N'
          AND wp.wp_customer_sk IN (9601898, 2172596, 1533463)
    )
      AND hd.hd_buy_potential = '501-1000'
      AND hd.hd_vehicle_count > 0
    GROUP BY
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        fr.fee_category
    HAVING COUNT(*) >= 5
)
SELECT
    ar.hd_buy_potential,
    ar.hd_vehicle_count,
    ar.fee_category,
    ar.return_cnt,
    ar.total_return_amt,
    ar.avg_return_amt,
    ar.total_fee,
    ar.max_ship_cost,
    RANK() OVER (PARTITION BY ar.hd_buy_potential ORDER BY ar.total_return_amt DESC) AS rank_by_return_amt,
    CASE
        WHEN ar.total_return_amt > 10000 THEN 'Very High'
        WHEN ar.total_return_amt > 5000 THEN 'High'
        WHEN ar.total_return_amt > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS total_return_category
FROM aggregated_returns ar
ORDER BY ar.total_return_amt DESC
LIMIT 100
