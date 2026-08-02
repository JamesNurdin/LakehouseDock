WITH base_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        AVG(ss.ss_coupon_amt) AS avg_coupon_amt,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        MAX(CASE WHEN h.d_holiday = 'Y' THEN 1 ELSE 0 END) AS is_holiday
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT OUTER JOIN (
        SELECT d_date_sk, d_holiday
        FROM date_dim
        WHERE d_holiday = 'Y'
    ) AS h
        ON ss.ss_sold_date_sk = h.d_date_sk
    WHERE
        d.d_current_month = 'Y'                         -- predicate 1
        AND d.d_dow IN (1, 2)                           -- predicate 2
        AND d.d_year = 1998                             -- predicate 3
        AND ss.ss_coupon_amt > 500                      -- predicate 4
        AND ss.ss_net_paid_inc_tax BETWEEN 100 AND 5000 -- predicate 5
        AND ss.ss_quantity > 1                         -- predicate 6
        AND ss.ss_ext_wholesale_cost < 4000             -- predicate 7
    GROUP BY
        d.d_year,
        d.d_month_seq
),
union_agg AS (
    SELECT
        d_year,
        d_month_seq,
        total_net_paid,
        avg_coupon_amt,
        distinct_items
    FROM base_agg
    WHERE is_holiday = 1
    UNION
    SELECT
        d_year,
        d_month_seq,
        total_net_paid,
        avg_coupon_amt,
        distinct_items
    FROM base_agg
    WHERE is_holiday = 0
)
SELECT
    u.d_year,
    u.d_month_seq,
    SUM(u.total_net_paid) AS sum_total_net_paid,
    AVG(u.avg_coupon_amt) AS avg_coupon_amt_over_union,
    SUM(u.distinct_items) AS total_distinct_items,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_sales ss_corr
        INNER JOIN date_dim d_corr
            ON ss_corr.ss_sold_date_sk = d_corr.d_date_sk
        WHERE d_corr.d_year = u.d_year
          AND d_corr.d_month_seq = u.d_month_seq
          AND ss_corr.ss_coupon_amt > 2000
    ) THEN 'HIGH' ELSE 'NORMAL' END AS coupon_level,
    (SUM(u.total_net_paid) / (SELECT SUM(ss2.ss_net_paid_inc_tax) FROM store_sales ss2)) AS pct_of_total_net_paid
FROM union_agg u
GROUP BY
    u.d_year,
    u.d_month_seq
ORDER BY
    sum_total_net_paid DESC
LIMIT 100
