WITH high_ship AS (
    SELECT
        reason.r_reason_desc,
        SUM(store_returns.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        'high_ship' AS category
    FROM store_returns
    JOIN customer ON store_returns.sr_customer_sk = customer.c_customer_sk
    JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
    WHERE store_returns.sr_return_ship_cost > 100
      AND customer.c_birth_year BETWEEN 1950 AND 1960
    GROUP BY reason.r_reason_desc
),
high_fee AS (
    SELECT
        reason.r_reason_desc,
        SUM(store_returns.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        'high_fee' AS category
    FROM store_returns
    JOIN customer ON store_returns.sr_customer_sk = customer.c_customer_sk
    JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
    WHERE store_returns.sr_fee > 30
      AND customer.c_birth_day = 15
    GROUP BY reason.r_reason_desc
)
SELECT
    high_ship.r_reason_desc,
    high_ship.total_loss,
    high_ship.return_cnt,
    high_ship.category
FROM high_ship
UNION ALL
SELECT
    high_fee.r_reason_desc,
    high_fee.total_loss,
    high_fee.return_cnt,
    high_fee.category
FROM high_fee
ORDER BY total_loss DESC, category
