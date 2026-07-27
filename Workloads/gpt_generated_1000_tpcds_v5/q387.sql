WITH ss_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_channel_catalog = 'N'
    GROUP BY p.p_promo_id, d.d_year
),
cr_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cr.cr_refunded_cash > 100
    GROUP BY p.p_promo_id, d.d_year
),
combined AS (
    SELECT
        promo_id,
        year,
        total_sales,
        total_profit,
        NULL AS total_returns,
        NULL AS total_loss,
        'sales' AS src
    FROM ss_agg
    UNION ALL
    SELECT
        promo_id,
        year,
        NULL AS total_sales,
        NULL AS total_profit,
        total_returns,
        total_loss,
        'returns' AS src
    FROM cr_agg
)
SELECT
    promo_id,
    year,
    src,
    total_sales,
    total_profit,
    total_returns,
    total_loss,
    RANK() OVER (
        PARTITION BY src
        ORDER BY CASE WHEN src = 'sales' THEN total_sales
                      WHEN src = 'returns' THEN total_returns
                 END DESC
    ) AS rank_within_src
FROM combined
ORDER BY promo_id, year, src
