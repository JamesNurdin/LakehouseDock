WITH sales AS (
    SELECT
        'sale' AS record_type,
        d.d_date,
        d.d_date_sk AS date_sk,
        s.s_store_name AS store_name,
        s.s_store_sk AS store_sk,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        SUM(ss.ss_quantity) AS total_quantity,
        CAST(NULL AS integer) AS distinct_reason_cnt,
        p.p_promo_name AS promo_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND d.d_weekend = 'N'
      AND (p.p_discount_active IS NULL OR p.p_discount_active = 'Y')
    GROUP BY d.d_date, d.d_date_sk, s.s_store_name, s.s_store_sk, p.p_promo_name
),
returns AS (
    SELECT
        'return' AS record_type,
        d.d_date,
        d.d_date_sk AS date_sk,
        s.s_store_name AS store_name,
        s.s_store_sk AS store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        SUM(sr.sr_return_quantity) AS total_quantity,
        COUNT(DISTINCT r.r_reason_id) AS distinct_reason_cnt,
        CAST(NULL AS varchar) AS promo_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND d.d_weekend = 'Y'
    GROUP BY d.d_date, d.d_date_sk, s.s_store_name, s.s_store_sk
),
combined AS (
    SELECT record_type, d_date, date_sk, store_name, store_sk, total_amount, total_quantity, distinct_reason_cnt, promo_name
    FROM sales
    UNION ALL
    SELECT record_type, d_date, date_sk, store_name, store_sk, total_amount, total_quantity, distinct_reason_cnt, promo_name
    FROM returns
)
SELECT
    c.record_type,
    c.d_date,
    c.store_name,
    c.total_amount,
    c.total_quantity,
    c.distinct_reason_cnt,
    c.promo_name,
    (
        SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = c.store_sk
          AND ss2.ss_sold_date_sk = c.date_sk
    ) AS store_daily_sales_total
FROM combined c
ORDER BY c.d_date DESC, c.total_amount DESC
LIMIT 100
