WITH site_open_close AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_name,
        ws.web_state,
        ws.web_class,
        ws.web_gmt_offset,
        ws.web_tax_percentage,
        od.d_year AS open_year,
        od.d_date AS open_date,
        cd.d_date AS close_date,
        date_diff('day', od.d_date, cd.d_date) AS lifespan_days
    FROM web_site ws
    JOIN date_dim od
        ON ws.web_open_date_sk = od.d_date_sk
    LEFT JOIN date_dim cd
        ON ws.web_close_date_sk = cd.d_date_sk
    WHERE od.d_year >= 2000
)

SELECT
    open_year,
    web_state,
    web_class,
    COUNT(web_site_sk) AS total_sites,
    AVG(web_gmt_offset) AS avg_gmt_offset,
    AVG(web_tax_percentage) AS avg_tax_percentage,
    AVG(lifespan_days) AS avg_lifespan_days,
    MAX(lifespan_days) AS max_lifespan_days,
    MIN(lifespan_days) AS min_lifespan_days
FROM site_open_close
GROUP BY open_year, web_state, web_class
ORDER BY open_year DESC, total_sites DESC
