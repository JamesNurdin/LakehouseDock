WITH small_dim AS (
    SELECT d.d_quarter_name,
           d.d_day_name
    FROM   date_dim d
    WHERE  d.d_current_week = 'N'
       AND d.d_day_name LIKE 'S%'
    LIMIT 5
),
promo_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(*)                                            AS return_cnt,
        SUM(wr.wr_net_loss)                                 AS total_net_loss,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d+)')          AS promo_number,
        CASE WHEN REGEXP_LIKE(p.p_promo_name, '[A-Z]{3}[0-9]{2}') THEN 'Match' ELSE 'NoMatch' END AS name_match_flag,
        SUBSTRING(p.p_promo_name FROM 1 FOR 5)              AS promo_prefix
    FROM   promotion p
    JOIN   date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN   web_returns wr ON wr.wr_returned_date_sk = d_start.d_date_sk
    GROUP BY
        p.p_promo_sk,
        p.p_promo_name,
        REGEXP_EXTRACT(p.p_promo_name, '(\\d+)'),
        CASE WHEN REGEXP_LIKE(p.p_promo_name, '[A-Z]{3}[0-9]{2}') THEN 'Match' ELSE 'NoMatch' END,
        SUBSTRING(p.p_promo_name FROM 1 FOR 5)
)
SELECT
    sd.d_quarter_name,
    sd.d_day_name,
    pa.p_promo_sk,
    pa.p_promo_name,
    pa.promo_number,
    pa.name_match_flag,
    pa.promo_prefix,
    pa.return_cnt,
    pa.total_net_loss,
    CONCAT(pa.p_promo_name, '_', sd.d_quarter_name) AS promo_quarter_concat
FROM   small_dim sd
CROSS JOIN promo_agg pa
ORDER BY pa.total_net_loss DESC
LIMIT 100
