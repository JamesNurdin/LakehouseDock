WITH press_returns AS (
    SELECT
        d.d_quarter_name AS quarter,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        'Press' AS promo_type
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN promotion p
        ON d.d_date_sk = p.p_start_date_sk
    WHERE p.p_channel_press = 'Y'
      AND d.d_date_sk <= p.p_end_date_sk
    GROUP BY d.d_quarter_name
    HAVING SUM(sr.sr_net_loss) > 1000
),
no_press_returns AS (
    SELECT
        d.d_quarter_name AS quarter,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt,
        'NoPress' AS promo_type
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p
        WHERE d.d_date_sk = p.p_start_date_sk
          AND d.d_date_sk <= p.p_end_date_sk
          AND p.p_channel_press = 'Y'
    )
    GROUP BY d.d_quarter_name
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    quarter,
    total_loss,
    returns_cnt,
    promo_type
FROM press_returns
UNION ALL
SELECT
    quarter,
    total_loss,
    returns_cnt,
    promo_type
FROM no_press_returns
ORDER BY quarter, total_loss DESC
