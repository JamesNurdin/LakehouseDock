WITH returns_agg AS (
    SELECT
        d.d_date AS date,
        sm.sm_carrier AS category,
        'return' AS source,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_net_loss) AS total_profit_loss,
        COUNT(*) AS transaction_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND hd.hd_buy_potential = '>10000'
    GROUP BY d.d_date, sm.sm_carrier
)
SELECT
    date,
    category,
    source,
    total_amount,
    total_profit_loss,
    transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_amount DESC) AS source_rank
FROM (
    SELECT
        date,
        category,
        source,
        total_amount,
        total_profit_loss,
        transaction_cnt
    FROM returns_agg
    UNION ALL
    SELECT
        d.d_date AS date,
        hd.hd_buy_potential AS category,
        'sale' AS source,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        SUM(ss.ss_net_profit) AS total_profit_loss,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND ss.ss_ext_tax > 50
      AND hd.hd_dep_count >= 2
    GROUP BY d.d_date, hd.hd_buy_potential
) AS combined
ORDER BY source, source_rank
LIMIT 100
