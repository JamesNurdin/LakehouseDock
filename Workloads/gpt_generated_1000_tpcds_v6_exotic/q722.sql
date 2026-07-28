WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ws.ws_net_paid,
        s.s_store_id,
        s.s_market_id,
        s.s_hours,
        s.s_rec_end_date,
        p.p_promo_id,
        p.p_discount_active,
        ws.ws_bill_addr_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE s.s_market_id = 2
      AND s.s_hours = '8AM-12AM'
      AND p.p_discount_active = 'Y'
      AND s.s_rec_end_date > DATE '2000-01-01'
)
SELECT *
FROM (
    SELECT
        CAST(b.s_store_id AS varchar)          AS dim1,
        CAST(b.p_promo_id AS varchar)          AS dim2,
        'store'                                 AS source,
        SUM(b.ss_net_paid)                     AS total_store_net,
        SUM(b.ws_net_paid)                     AS total_web_net,
        COUNT(*)                               AS txn_count
    FROM base b
    GROUP BY GROUPING SETS (
        (b.s_store_id, b.p_promo_id),
        (b.s_store_id),
        (b.p_promo_id)
    )
    HAVING (SUM(b.ss_net_paid) + SUM(b.ws_net_paid)) > 10000

    UNION ALL

    SELECT
        CAST(b.p_promo_id AS varchar)          AS dim1,
        CAST(b.ws_bill_addr_sk AS varchar)     AS dim2,
        'web'                                   AS source,
        SUM(b.ss_net_paid)                     AS total_store_net,
        SUM(b.ws_net_paid)                     AS total_web_net,
        COUNT(*)                               AS txn_count
    FROM base b
    GROUP BY GROUPING SETS (
        (b.p_promo_id, b.ws_bill_addr_sk),
        (b.p_promo_id),
        (b.ws_bill_addr_sk)
    )
    HAVING (SUM(b.ss_net_paid) + SUM(b.ws_net_paid)) > 10000
) AS combined
ORDER BY source, total_store_net DESC
LIMIT 100
