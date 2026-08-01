WITH
    store_agg AS (
        SELECT
            ca.ca_county,
            d.d_year,
            SUM(ss.ss_net_paid) AS store_net_paid,
            CASE WHEN SUM(ss.ss_net_paid) > 20000 THEN 'High' ELSE 'Low' END AS sales_category
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_holiday = 'N'
        GROUP BY GROUPING SETS (
            (ca.ca_county, d.d_year),
            (ca.ca_county),
            (d.d_year)
        )
        HAVING ca.ca_county IS NOT NULL AND d.d_year IS NOT NULL
    ),
    web_agg AS (
        SELECT
            ca.ca_county,
            d.d_year,
            SUM(ws.ws_net_paid) AS web_net_paid,
            CASE WHEN SUM(ws.ws_net_paid) > 15000 THEN 'High' ELSE 'Low' END AS sales_category
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        WHERE d.d_holiday = 'N'
        GROUP BY GROUPING SETS (
            (ca.ca_county, d.d_year),
            (ca.ca_county),
            (d.d_year)
        )
        HAVING ca.ca_county IS NOT NULL AND d.d_year IS NOT NULL
    ),
    common_county_year AS (
        SELECT ca_county, d_year FROM store_agg
        INTERSECT
        SELECT ca_county, d_year FROM web_agg
    ),
    all_counties AS (
        SELECT DISTINCT ca_county FROM customer_address
    ),
    counties_without_both AS (
        SELECT ca_county FROM all_counties
        EXCEPT
        SELECT ca_county FROM common_county_year
    ),
    year_vals AS (
        SELECT 2020 AS d_year UNION ALL SELECT 2021
    )
SELECT
    final.ca_county,
    final.d_year,
    SUM(final.store_sales) AS store_sales,
    SUM(final.web_sales) AS web_sales,
    CASE
        WHEN SUM(final.store_sales) + SUM(final.web_sales) > 50000 THEN 'Huge'
        WHEN SUM(final.store_sales) + SUM(final.web_sales) > 0 THEN 'Normal'
        ELSE 'None'
    END AS total_category
FROM (
    -- Store side of common county-year
    SELECT
        cca.ca_county,
        cca.d_year,
        sa.store_net_paid AS store_sales,
        0.0 AS web_sales
    FROM common_county_year cca
    JOIN store_agg sa ON sa.ca_county = cca.ca_county AND sa.d_year = cca.d_year

    UNION ALL

    -- Web side of common county-year
    SELECT
        cca.ca_county,
        cca.d_year,
        0.0 AS store_sales,
        wa.web_net_paid AS web_sales
    FROM common_county_year cca
    JOIN web_agg wa ON wa.ca_county = cca.ca_county AND wa.d_year = cca.d_year

    UNION ALL

    -- Counties that appear in only one channel, crossed with a small year set
    SELECT
        cwb.ca_county,
        y.d_year,
        COALESCE(sa.store_net_paid, 0.0) AS store_sales,
        COALESCE(wa.web_net_paid, 0.0) AS web_sales
    FROM counties_without_both cwb
    CROSS JOIN year_vals y
    LEFT JOIN store_agg sa ON sa.ca_county = cwb.ca_county AND sa.d_year = y.d_year
    LEFT JOIN web_agg wa ON wa.ca_county = cwb.ca_county AND wa.d_year = y.d_year
) final
GROUP BY GROUPING SETS (
    (final.ca_county, final.d_year),
    (final.ca_county),
    (final.d_year)
)
ORDER BY final.ca_county NULLS LAST, final.d_year
LIMIT 100
