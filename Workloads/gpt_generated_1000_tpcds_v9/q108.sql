WITH distinct_holidays AS (
    SELECT DISTINCT d_date_sk, d_day_name, d_holiday, d_weekend
    FROM date_dim
    WHERE d_weekend = 'Y'
),
filtered_dates AS (
    SELECT
        dh.d_date_sk,
        dh.d_day_name,
        dh.d_holiday,
        CONCAT(dh.d_day_name, ' - ', dh.d_holiday) AS day_holiday,
        CASE
            WHEN regexp_like(dh.d_holiday, '^.*Day$') THEN 'EndsWithDay'
            ELSE 'OtherHoliday'
        END AS holiday_category,
        regexp_extract(dh.d_holiday, '([A-Za-z]+) Day', 1) AS holiday_base,
        substr(dh.d_day_name, 1, 3) AS day_abbrev
    FROM distinct_holidays dh
    WHERE dh.d_holiday IS NOT NULL
      AND (regexp_like(dh.d_holiday, '^.*Day$') OR dh.d_holiday LIKE '%Day%')
),
sales_agg AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
),
returns_agg AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr_order_number) AS distinct_returns
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
)
SELECT DISTINCT
    fd.d_date_sk,
    fd.day_holiday,
    fd.holiday_category,
    fd.holiday_base,
    fd.day_abbrev,
    sa.total_net_paid,
    sa.total_net_profit,
    ra.total_net_loss,
    CASE
        WHEN sa.total_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag
FROM filtered_dates fd
JOIN sales_agg sa ON fd.d_date_sk = sa.date_sk
LEFT JOIN returns_agg ra ON fd.d_date_sk = ra.date_sk
WHERE sa.total_net_profit > (SELECT AVG(cs_net_profit) FROM catalog_sales)
  AND fd.d_day_name LIKE 'S%'
ORDER BY sa.total_net_profit DESC
LIMIT 100
