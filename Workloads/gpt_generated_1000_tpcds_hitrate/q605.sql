WITH filtered_stores AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_division_id
    FROM store s
    WHERE regexp_like(s.s_city, '^San')
      AND s.s_state LIKE 'CA%'
),
store_sales_agg AS (
    SELECT
        fs.s_store_sk,
        concat(fs.s_store_name, ' (', fs.s_city, ')') AS store_full_name,
        regexp_extract(fs.s_city, '^(\\w+)', 1) AS city_prefix,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(r.sr_ticket_number) AS return_count,
        CASE WHEN SUM(ss.ss_net_paid) > 5000 THEN 'PROFITABLE' ELSE 'LOW_PROFIT' END AS profit_category,
        (
            SELECT avg(cs.cs_net_paid)
            FROM catalog_sales cs
            JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
            WHERE cc.cc_division = fs.s_division_id
        ) AS avg_catalog_net_paid
    FROM filtered_stores fs
    JOIN store_sales ss ON ss.ss_store_sk = fs.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns r
        ON r.sr_ticket_number = ss.ss_ticket_number
        AND r.sr_store_sk = fs.s_store_sk
    GROUP BY
        fs.s_store_sk,
        fs.s_store_name,
        fs.s_city,
        fs.s_state,
        fs.s_division_id,
        concat(fs.s_store_name, ' (', fs.s_city, ')'),
        regexp_extract(fs.s_city, '^(\\w+)', 1),
        d.d_year
)
SELECT *
FROM store_sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
