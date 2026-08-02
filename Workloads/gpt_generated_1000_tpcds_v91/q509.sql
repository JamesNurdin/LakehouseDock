WITH catalog_agg AS (
    SELECT
        dd.d_year AS year,
        cc.cc_state AS state,
        CONCAT(cc.cc_state, '_', CAST(dd.d_year AS VARCHAR)) AS state_year_key,
        SUM(cr.cr_net_loss) AS total_net_loss,
        (
            SELECT AVG(cr2.cr_net_loss)
            FROM catalog_returns cr2
            JOIN date_dim dd2 ON cr2.cr_returned_date_sk = dd2.d_date_sk
            WHERE dd2.d_year = dd.d_year
        ) AS avg_loss,
        'catalog' AS source,
        MIN(SUBSTR(i.i_item_desc, 1, 10)) AS sample_text
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = dd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '\\d{3}')
      AND p.p_promo_name LIKE 'Discount%'
      AND dd.d_date >= DATE '2020-01-01'
      AND dd.d_date < DATE '2021-01-01'
    GROUP BY dd.d_year, cc.cc_state
),
web_agg AS (
    SELECT
        dd.d_year AS year,
        cc.cc_state AS state,
        CONCAT(cc.cc_state, '_', CAST(dd.d_year AS VARCHAR)) AS state_year_key,
        SUM(wr.wr_net_loss) AS total_net_loss,
        (
            SELECT AVG(wr2.wr_net_loss)
            FROM web_returns wr2
            JOIN date_dim dd2 ON wr2.wr_returned_date_sk = dd2.d_date_sk
            WHERE dd2.d_year = dd.d_year
        ) AS avg_loss,
        'web' AS source,
        MIN(REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)', 1)) AS sample_text
    FROM web_returns wr
    JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = dd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE REGEXP_LIKE(wp.wp_url, '^https?://.*\\.com')
      AND i.i_color LIKE '%Red%'
      AND dd.d_date >= DATE '2020-01-01'
      AND dd.d_date < DATE '2021-01-01'
    GROUP BY dd.d_year, cc.cc_state
)
SELECT * FROM catalog_agg
UNION
SELECT * FROM web_agg
ORDER BY year DESC, state, source
LIMIT 100
