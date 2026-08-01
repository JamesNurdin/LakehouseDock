WITH combined_metrics AS (
    SELECT
        COALESCE(d_ws.d_year, d_promo.d_year) AS year_val,
        'PromoNetProfit' AS metric_category,
        SUM(ws.ws_net_profit) AS amount,
        p.p_promo_id AS promo_id
    FROM web_sales ws
    FULL OUTER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN date_dim d_promo
        ON p.p_start_date_sk = d_promo.d_date_sk
    WHERE COALESCE(d_ws.d_year, d_promo.d_year) BETWEEN 1999 AND 2001
    GROUP BY COALESCE(d_ws.d_year, d_promo.d_year), p.p_promo_id

    UNION ALL

    SELECT
        d.d_year AS year_val,
        'StoreReturnLoss' AS metric_category,
        -SUM(sr.sr_refunded_cash) AS amount,
        CAST(NULL AS varchar) AS promo_id
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year
)
SELECT
    cm.year_val,
    cm.metric_category,
    cm.amount,
    cm.promo_id
FROM combined_metrics cm
WHERE cm.amount > (SELECT AVG(ws.ws_net_profit) FROM web_sales ws)
   OR cm.metric_category = 'StoreReturnLoss'
ORDER BY cm.year_val,
         cm.metric_category,
         cm.amount DESC
LIMIT 100
