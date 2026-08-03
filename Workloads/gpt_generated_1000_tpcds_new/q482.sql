WITH date_info AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        ARRAY[CAST(d.d_day_name AS varchar), CAST(d.d_month_seq AS varchar)] AS info_array
    FROM date_dim d
),
sub_a AS (
    SELECT
        info_elem AS info,
        di.d_year AS year,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    RIGHT JOIN date_info di
        ON cr.cr_returned_date_sk = di.d_date_sk
    CROSS JOIN UNNEST(di.info_array) AS t(info_elem)
    WHERE di.d_year BETWEEN 2000 AND 2002
    GROUP BY info_elem, di.d_year
    HAVING SUM(cr.cr_net_loss) > 1000
),
sub_b AS (
    SELECT
        info_elem AS info,
        di.d_year AS year,
        SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    RIGHT JOIN date_info di
        ON wr.wr_returned_date_sk = di.d_date_sk
    CROSS JOIN UNNEST(di.info_array) AS t(info_elem)
    WHERE di.d_year BETWEEN 2000 AND 2002
    GROUP BY info_elem, di.d_year
    HAVING SUM(wr.wr_net_loss) > 1000
)
SELECT info, year, total_loss FROM sub_a
INTERSECT
SELECT info, year, total_loss FROM sub_b
ORDER BY total_loss DESC, info, year
LIMIT 100
