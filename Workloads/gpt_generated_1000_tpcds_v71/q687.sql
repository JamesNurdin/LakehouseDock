WITH store_agg AS (
    SELECT
        p.p_promo_id,
        concat(p.p_promo_id, '-', d.d_quarter_name) AS promo_quarter,
        regexp_extract(p.p_promo_name, '(Discount|Sale)', 1) AS promo_type,
        COUNT(*) AS store_return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE regexp_like(p.p_promo_name, '(Discount|Sale)')
      AND d.d_quarter_name LIKE '1902%'
      AND NOT EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_returned_date_sk = sr.sr_returned_date_sk
              AND sr2.sr_net_loss > 100
        )
    GROUP BY p.p_promo_id, d.d_quarter_name, p.p_promo_name, d.d_year
),
web_agg AS (
    SELECT
        p.p_promo_id,
        concat(p.p_promo_id, '-', d.d_quarter_name) AS promo_quarter,
        regexp_extract(p.p_promo_name, '(Discount|Sale)', 1) AS promo_type,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE regexp_like(p.p_promo_name, '(Discount|Sale)')
      AND d.d_quarter_name LIKE '1902%'
      AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
              AND wr2.wr_net_loss > 100
        )
    GROUP BY p.p_promo_id, d.d_quarter_name, p.p_promo_name, d.d_year
)
SELECT *
FROM (
    SELECT
        promo_quarter,
        promo_type,
        store_return_cnt AS return_cnt,
        total_return_amt,
        avg_return_amt,
        d_year,
        'store' AS source
    FROM store_agg
    UNION ALL
    SELECT
        promo_quarter,
        promo_type,
        web_return_cnt AS return_cnt,
        total_return_amt,
        avg_return_amt,
        d_year,
        'web' AS source
    FROM web_agg
) combined
WHERE return_cnt > 5
ORDER BY d_year DESC, total_return_amt DESC
LIMIT 100
