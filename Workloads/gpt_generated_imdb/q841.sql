WITH kw_movie_counts AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        k.phonetic_code,
        COUNT(DISTINCT mk.movie_id) AS movie_cnt
    FROM keyword k
    JOIN movie_keyword mk
        ON mk.keyword_id = k.id
    GROUP BY k.id, k.keyword, k.phonetic_code
),
phonetic_stats AS (
    SELECT
        phonetic_code,
        COUNT(*) AS kw_cnt_per_phonetic
    FROM keyword
    GROUP BY phonetic_code
)
SELECT
    kmc.keyword,
    kmc.phonetic_code,
    kmc.movie_cnt,
    ps.kw_cnt_per_phonetic,
    kmc.movie_cnt * 1.0 / ps.kw_cnt_per_phonetic AS movies_per_keyword_in_phonetic,
    RANK() OVER (PARTITION BY kmc.phonetic_code ORDER BY kmc.movie_cnt DESC) AS rank_in_phonetic
FROM kw_movie_counts kmc
JOIN phonetic_stats ps
    ON kmc.phonetic_code = ps.phonetic_code
ORDER BY kmc.movie_cnt DESC
LIMIT 20
