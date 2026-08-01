WITH returns_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_reversed_charge > 100.00
      AND cr_return_amount > 10.00
      AND cr_return_quantity > 0
      AND cr_fee >= 0.00
      AND cr_return_tax >= 0.00
      AND cr_return_ship_cost >= 0.00
    GROUP BY cr_returned_date_sk, cr_ship_mode_sk
),
agg_2001 AS (
    SELECT
        d.d_year AS year,
        s.sm_code AS ship_mode_code,
        s.sm_type AS ship_mode_type,
        SUM(ra.total_return_amount) AS sum_return_amount,
        AVG(ra.total_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ra.cr_returned_date_sk) AS distinct_return_dates
    FROM returns_agg ra
    JOIN date_dim d ON ra.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode s ON ra.cr_ship_mode_sk = s.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND d.d_following_holiday = 'N'
      AND d.d_date_id LIKE 'AAAAAAA%'
      AND s.sm_code = 'AIR'
      AND s.sm_contract = 'qENFQ'
    GROUP BY d.d_year, s.sm_code, s.sm_type
    HAVING SUM(ra.total_return_amount) > 1000
),
agg_2002 AS (
    SELECT
        d.d_year AS year,
        s.sm_code AS ship_mode_code,
        s.sm_type AS ship_mode_type,
        SUM(ra.total_return_amount) AS sum_return_amount,
        AVG(ra.total_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ra.cr_returned_date_sk) AS distinct_return_dates
    FROM returns_agg ra
    JOIN date_dim d ON ra.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode s ON ra.cr_ship_mode_sk = s.sm_ship_mode_sk
    WHERE d.d_year = 2002
      AND d.d_month_seq BETWEEN 1300 AND 1400
      AND d.d_following_holiday = 'Y'
      AND d.d_date_id LIKE 'AAAAAAAP%'
      AND s.sm_code = 'SEA'
      AND s.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
    GROUP BY d.d_year, s.sm_code, s.sm_type
    HAVING SUM(ra.total_return_amount) > 2000
),
ranked_2001 AS (
    SELECT
        year,
        ship_mode_code,
        ship_mode_type,
        sum_return_amount,
        avg_return_amount,
        distinct_return_dates,
        RANK() OVER (PARTITION BY year ORDER BY sum_return_amount DESC) AS rank_by_amount
    FROM agg_2001
),
ranked_2002 AS (
    SELECT
        year,
        ship_mode_code,
        ship_mode_type,
        sum_return_amount,
        avg_return_amount,
        distinct_return_dates,
        RANK() OVER (PARTITION BY year ORDER BY sum_return_amount DESC) AS rank_by_amount
    FROM agg_2002
)
SELECT
    year,
    ship_mode_code,
    ship_mode_type,
    sum_return_amount,
    avg_return_amount,
    distinct_return_dates,
    rank_by_amount
FROM ranked_2001
UNION ALL
SELECT
    year,
    ship_mode_code,
    ship_mode_type,
    sum_return_amount,
    avg_return_amount,
    distinct_return_dates,
    rank_by_amount
FROM ranked_2002
ORDER BY year DESC, sum_return_amount DESC
LIMIT 100
