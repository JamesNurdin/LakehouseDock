WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cp.cp_description,
        cp.cp_catalog_page_id,
        sm.sm_ship_mode_id,
        sm.sm_code,
        d.d_date
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount')
      AND sm.sm_code = 'AIR'
      AND d.d_year = 2000
)
SELECT
    fr.d_date,
    fr.cp_catalog_page_id,
    regexp_extract(fr.cp_catalog_page_id, '[0-9]+') AS page_num,
    fr.sm_ship_mode_id,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_sales ws
            JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
            JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
            WHERE sm2.sm_ship_mode_sk = fr.cr_ship_mode_sk
              AND d2.d_date = fr.d_date
              AND ws.ws_net_profit > 0
        ) THEN 'Has Sales'
        ELSE 'No Sales'
    END AS sales_indicator
FROM filtered_returns fr
GROUP BY
    fr.d_date,
    fr.cp_catalog_page_id,
    regexp_extract(fr.cp_catalog_page_id, '[0-9]+'),
    fr.sm_ship_mode_id,
    fr.cr_ship_mode_sk
ORDER BY total_return_amount DESC
LIMIT 100
