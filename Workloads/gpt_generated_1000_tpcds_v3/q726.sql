WITH reason_returns AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        d.d_year,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM
        catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    GROUP BY
        r.r_reason_id,
        r.r_reason_desc,
        d.d_year
)
SELECT
    rr.r_reason_id,
    rr.r_reason_desc,
    rr.d_year,
    rr.catalog_net_loss,
    rr.web_net_loss,
    (rr.catalog_net_loss + rr.web_net_loss) AS total_net_loss,
    ((rr.catalog_net_loss + rr.web_net_loss) / NULLIF(
        (SELECT SUM(total) FROM (
            SELECT SUM(cr.cr_net_loss) AS total FROM catalog_returns cr
            UNION ALL
            SELECT SUM(wr.wr_net_loss) AS total FROM web_returns wr
        ) overall
    ), 0)) AS loss_proportion,
    CASE WHEN regexp_like(rr.r_reason_desc, '(?i)damage') THEN 'ContainsDamage' ELSE 'Other' END AS reason_category,
    SUBSTRING(rr.r_reason_desc FROM 1 FOR 10) AS reason_prefix,
    CONCAT(rr.r_reason_id, '_', CAST(rr.d_year AS VARCHAR)) AS reason_year_key,
    CASE WHEN EXISTS (
        SELECT 1
        FROM promotion p
        JOIN date_dim dp ON p.p_start_date_sk = dp.d_date_sk
        WHERE dp.d_year = rr.d_year
          AND p.p_channel_catalog = 'Y'
    ) THEN 1 ELSE 0 END AS has_catalog_promo_in_year
FROM reason_returns rr
WHERE rr.r_reason_id LIKE 'AAAA%'
  AND regexp_like(rr.r_reason_desc, '^.{0,20}$')
ORDER BY total_net_loss DESC
LIMIT 100
