WITH sales_agg AS (
    SELECT
        d.d_date_sk,
        d.d_day_name,
        d.d_holiday,
        CONCAT(d.d_day_name, ' - ', COALESCE(d.d_holiday, 'NoHoliday')) AS day_holiday_desc,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND d.d_day_name LIKE 'S%'
    GROUP BY
        d.d_date_sk,
        d.d_day_name,
        d.d_holiday,
        CONCAT(d.d_day_name, ' - ', COALESCE(d.d_holiday, 'NoHoliday'))
),
returns_agg AS (
    SELECT
        d.d_date_sk,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND REGEXP_LIKE(d.d_holiday, '^.*Day$')
    GROUP BY d.d_date_sk
)
SELECT
    s.day_holiday_desc,
    s.d_day_name,
    s.d_holiday,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE WHEN s.total_sales = 0 THEN NULL ELSE COALESCE(r.total_returns, 0) / s.total_sales END AS return_to_sales_ratio
FROM sales_agg s
LEFT JOIN returns_agg r ON s.d_date_sk = r.d_date_sk
ORDER BY s.total_sales DESC
LIMIT 100
