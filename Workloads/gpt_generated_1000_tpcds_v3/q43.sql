WITH store_sales_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        s.s_store_id AS store_id,
        p.p_promo_id AS promo_id,
        SUM(ss.ss_net_paid) AS total_amount,
        'store_sales' AS source
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 0
    GROUP BY hd.hd_demo_sk, s.s_store_id, p.p_promo_id
),
web_returns_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        'WEB' AS store_id,
        CAST(NULL AS varchar) AS promo_id,
        SUM(wr.wr_refunded_cash) AS total_amount,
        'web_returns' AS source
    FROM tpcds.web_returns wr
    JOIN tpcds.household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 0
    GROUP BY hd.hd_demo_sk
)
SELECT
    demo_sk,
    store_id,
    promo_id,
    total_amount,
    source,
    RANK() OVER (PARTITION BY source ORDER BY total_amount DESC) AS amount_rank
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_returns_agg
) u
ORDER BY total_amount DESC
LIMIT 100
