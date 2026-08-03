WITH sampled_store AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_market_desc,
        s_closed_date_sk
    FROM store TABLESAMPLE BERNOULLI (10)
    WHERE s_closed_date_sk IS NOT NULL
),
first_part AS (
    SELECT
        d.d_quarter_seq AS quarter,
        regexp_extract(s.s_market_desc, '(\\w+)', 1) AS market_word,
        COUNT(*) AS closed_cnt
    FROM sampled_store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE regexp_like(s.s_store_name, '^.*Store.*$')
      AND s.s_market_desc LIKE '%Events%'
    GROUP BY d.d_quarter_seq, regexp_extract(s.s_market_desc, '(\\w+)', 1)
),
second_part AS (
    SELECT
        d.d_quarter_seq AS quarter,
        regexp_extract(s.s_market_desc, '(\\w+)', 1) AS market_word,
        COUNT(*) AS closed_cnt
    FROM sampled_store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE regexp_like(s.s_store_name, '^.*Market.*$')
      AND s.s_market_desc LIKE '%Formal%'
    GROUP BY d.d_quarter_seq, regexp_extract(s.s_market_desc, '(\\w+)', 1)
)
SELECT
    quarter,
    market_word,
    SUM(closed_cnt) AS total_closed
FROM (
    SELECT quarter, market_word, closed_cnt FROM first_part
    UNION DISTINCT
    SELECT quarter, market_word, closed_cnt FROM second_part
) u
GROUP BY quarter, market_word
ORDER BY quarter DESC, total_closed DESC
LIMIT 100
