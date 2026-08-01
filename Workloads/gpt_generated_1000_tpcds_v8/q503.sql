WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
),
price_reasons AS (
    SELECT DISTINCT sr.sr_reason_sk
    FROM sampled_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'price')
),
warranty_reasons AS (
    SELECT DISTINCT sr.sr_reason_sk
    FROM sampled_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'warranty')
),
-- reasons that appear for "price" but not for "warranty"
price_not_warranty AS (
    SELECT sr_reason_sk
    FROM price_reasons
    EXCEPT
    SELECT sr_reason_sk
    FROM warranty_reasons
),
joined_data AS (
    SELECT
        sr.sr_reason_sk,
        r.r_reason_desc,
        sr.sr_net_loss,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_reversed_charge,
        ARRAY[sr.sr_return_amt_inc_tax, sr.sr_fee, sr.sr_reversed_charge] AS metrics
    FROM sampled_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_reason_sk IN (SELECT sr_reason_sk FROM price_not_warranty)
      AND r.r_reason_desc LIKE '%better%'
),
unnested AS (
    SELECT
        jd.sr_reason_sk,
        jd.r_reason_desc,
        metric,
        CONCAT(SUBSTR(jd.r_reason_desc, 1, 10), '_', CAST(jd.sr_reason_sk AS varchar)) AS reason_key
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.metrics) AS t(metric)
),
avg_loss AS (
    SELECT
        sr_reason_sk,
        avg(sr_net_loss) AS avg_net_loss
    FROM sampled_returns
    GROUP BY sr_reason_sk
)
SELECT
    u.r_reason_desc,
    u.metric,
    u.reason_key,
    COUNT(*) AS cnt,
    SUM(u.metric) AS total_metric
FROM unnested u
JOIN avg_loss al ON u.sr_reason_sk = al.sr_reason_sk
WHERE u.metric > al.avg_net_loss
GROUP BY CUBE (u.r_reason_desc, u.metric, u.reason_key)
HAVING SUM(u.metric) > 0
ORDER BY u.r_reason_desc ASC, total_metric DESC
