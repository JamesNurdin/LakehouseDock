WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_ship_cost,
        cr.cr_return_tax,
        cr.cr_net_loss,
        d.d_date_sk,
        d.d_date,
        d.d_year,
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_street_type,
        cc.cc_name
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_city LIKE 'A%'
      AND regexp_like(cc.cc_street_type, '^(Avenue|Boulevard|Drive|Way|Ct\\.)$')
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_date_sk = d.d_date_sk
            AND inv.inv_quantity_on_hand > 0
      )
),
aggregated AS (
    SELECT
        f.cc_call_center_id,
        f.cc_city,
        f.cc_street_type,
        f.cc_name,
        f.d_year,
        f.d_date,
        f.d_date_sk,
        COUNT(*) AS total_returns,
        SUM(f.cr_return_amount) AS total_return_amount,
        AVG(f.cr_return_amount) AS avg_return_amount
    FROM filtered f
    GROUP BY
        f.cc_call_center_id,
        f.cc_city,
        f.cc_street_type,
        f.cc_name,
        f.d_year,
        f.d_date,
        f.d_date_sk
)
SELECT
    a.cc_call_center_id,
    a.cc_city,
    a.cc_street_type,
    CONCAT(SUBSTRING(a.cc_name, 1, 5), '_CC') AS cc_name_code,
    a.d_year,
    a.d_date,
    a.total_returns,
    a.total_return_amount,
    a.avg_return_amount,
    CASE
        WHEN a.total_return_amount > 15000 THEN 'Very High'
        WHEN a.total_return_amount > 5000 THEN 'High'
        ELSE 'Moderate'
    END AS return_intensity,
    REGEXP_EXTRACT(a.cc_street_type, '(Avenue|Boulevard|Drive|Way|Ct\\.)', 1) AS street_type_extracted,
    SUM(a.total_return_amount) OVER (
        PARTITION BY a.cc_call_center_id
        ORDER BY a.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount,
    ROW_NUMBER() OVER (
        PARTITION BY a.cc_city, a.d_year
        ORDER BY a.total_return_amount DESC
    ) AS city_year_return_rank,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
     WHERE d2.d_year = a.d_year) AS year_avg_return_amount
FROM aggregated a
JOIN store s
    ON s.s_closed_date_sk = a.d_date_sk
WHERE s.s_state = 'CA'
ORDER BY a.total_return_amount DESC, a.cc_city ASC
LIMIT 100
