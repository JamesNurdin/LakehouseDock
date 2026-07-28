WITH returns_filtered AS (
    SELECT
        cr.cr_return_amount,
        w.w_state,
        w.w_city,
        concat(w.w_city, ', ', w.w_state) AS location
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_item_desc, '(?i)portable')
      AND w.w_street_type LIKE 'St%'
      AND w.w_city LIKE 'San%'
      AND regexp_like(w.w_zip, '^[0-9]{5}$')
)
SELECT
    w_state,
    w_city,
    location,
    sum(cr_return_amount) AS total_return_amount,
    count(*) AS returns_count
FROM returns_filtered
GROUP BY w_state, w_city, location
ORDER BY total_return_amount DESC
LIMIT 100
