WITH store_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        d.d_date AS return_date,
        SUM(sr.sr_net_loss) AS total_net_loss,
        (SELECT COUNT(*) FROM promotion p WHERE p.p_start_date_sk = d.d_date_sk) AS promo_start_cnt,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc, d.d_date, d.d_date_sk
),
catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        d.d_date AS return_date,
        SUM(cr.cr_net_loss) AS total_net_loss,
        (SELECT COUNT(*) FROM promotion p WHERE p.p_start_date_sk = d.d_date_sk) AS promo_start_cnt,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc, d.d_date, d.d_date_sk
)
SELECT
    reason_desc,
    return_date,
    total_net_loss,
    promo_start_cnt,
    source
FROM store_ret
UNION ALL
SELECT
    reason_desc,
    return_date,
    total_net_loss,
    promo_start_cnt,
    source
FROM catalog_ret
ORDER BY total_net_loss DESC
LIMIT 100
