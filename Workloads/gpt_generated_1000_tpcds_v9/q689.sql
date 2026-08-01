WITH filtered_catalog AS (
    SELECT DISTINCT
        cp.cp_catalog_page_id,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        cp.cp_type,
        cp.cp_description,
        CASE
            WHEN regexp_like(cp.cp_description, '(?i)years') THEN 'has_years'
            ELSE 'no_years'
        END AS years_flag,
        regexp_extract(cp.cp_description, '^([A-Za-z]+)', 1) AS first_word
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '[0-9]')
      AND cp.cp_type LIKE 'qu%'
),
agg_returns AS (
    SELECT
        d.d_date AS return_date,
        d.d_year AS d_year,
        fc.cp_type AS cp_type,
        fc.years_flag AS years_flag,
        fc.first_word AS first_word,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CONCAT(fc.first_word, '-', fc.cp_type) AS type_code,
        (
            SELECT MAX(wr2.wr_return_amt_inc_tax)
            FROM web_returns wr2
            WHERE wr2.wr_returned_date_sk = d.d_date_sk
        ) AS max_return_amt_inc_tax
    FROM filtered_catalog fc
    JOIN date_dim d ON fc.cp_start_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND (p.p_channel_demo = 'N' OR p.p_channel_demo IS NULL)
      AND fc.cp_description LIKE '%see%'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_start_date_sk = d.d_date_sk
            AND p2.p_channel_demo = 'N'
      )
      AND t.t_hour BETWEEN 12 AND 23
    GROUP BY d.d_date, d.d_year, fc.cp_type, fc.years_flag, fc.first_word, d.d_date_sk
)
SELECT
    a.return_date,
    a.d_year,
    a.cp_type,
    a.years_flag,
    a.first_word,
    a.type_code,
    a.distinct_promos,
    a.total_return_qty,
    a.total_net_loss,
    CASE
        WHEN a.total_net_loss > 1000 THEN 'High Loss'
        WHEN a.total_net_loss > 0 THEN 'Medium Loss'
        ELSE 'Low/No Loss'
    END AS loss_category,
    a.max_return_amt_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg_returns a
ORDER BY a.d_year, loss_rank
LIMIT 100
