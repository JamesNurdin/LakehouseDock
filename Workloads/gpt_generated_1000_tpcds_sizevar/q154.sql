WITH base AS (
    SELECT
        dr.d_year,
        cc.cc_division_name,
        SUM(r.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM store_returns r
    JOIN date_dim dr ON r.sr_returned_date_sk = dr.d_date_sk
    JOIN customer cu ON r.sr_customer_sk = cu.c_customer_sk
    JOIN customer_address ad ON cu.c_current_addr_sk = ad.ca_address_sk
    JOIN call_center cc ON cc.cc_open_date_sk = dr.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = dr.d_date_sk
    WHERE dr.d_holiday = 'N'
      AND regexp_like(cu.c_email_address, '\\.org$')
      AND regexp_like(cc.cc_suite_number, '^Suite [0-9]+')
      AND ad.ca_suite_number LIKE 'Suite %'
      AND cp.cp_description LIKE '%sale%'
    GROUP BY GROUPING SETS (
        (dr.d_year, cc.cc_division_name),
        (dr.d_year),
        (cc.cc_division_name)
    )
)
SELECT
    d_year,
    cc_division_name,
    total_return_amount,
    return_count,
    LAG(total_return_amount) OVER (
        PARTITION BY COALESCE(cc_division_name, 'ALL')
        ORDER BY d_year
    ) AS prev_year_return_amount,
    SUM(total_return_amount) OVER (
        PARTITION BY COALESCE(cc_division_name, 'ALL')
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_return_amount
FROM base
ORDER BY d_year DESC, cc_division_name
LIMIT 100
