WITH monthly_store AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT CASE WHEN c.c_preferred_cust_flag = 'Y' THEN ss.ss_customer_sk END) AS preferred_customers
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
monthly_promo AS (
    SELECT
        ss.ss_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(p.p_cost) AS total_promo_cost,
        SUM(ss.ss_ext_discount_amt) AS promo_discount_total,
        COUNT(DISTINCT ss.ss_promo_sk) AS distinct_promos
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
store_rank AS (
    SELECT
        ms.ss_store_sk,
        ms.d_year,
        ms.d_month_seq,
        ms.total_net_paid,
        ms.total_discount,
        ms.total_net_profit,
        ms.distinct_customers,
        ms.preferred_customers,
        mp.total_promo_cost,
        mp.promo_discount_total,
        mp.distinct_promos,
        DENSE_RANK() OVER (PARTITION BY ms.d_year, ms.d_month_seq ORDER BY ms.total_net_paid DESC) AS sales_rank,
        CASE
            WHEN ms.total_discount > (
                SELECT AVG(total_discount)
                FROM monthly_store
                WHERE d_year = ms.d_year AND d_month_seq = ms.d_month_seq
            ) THEN 'Above Avg Discount'
            ELSE 'Below Avg Discount'
        END AS discount_category
    FROM monthly_store ms
    LEFT JOIN monthly_promo mp
        ON ms.ss_store_sk = mp.ss_store_sk
        AND ms.d_year = mp.d_year
        AND ms.d_month_seq = mp.d_month_seq
)
SELECT
    sr.ss_store_sk,
    sr.d_year,
    sr.d_month_seq,
    sr.total_net_paid,
    sr.total_discount,
    sr.total_net_profit,
    sr.distinct_customers,
    sr.preferred_customers,
    sr.total_promo_cost,
    sr.promo_discount_total,
    sr.distinct_promos,
    sr.sales_rank,
    sr.discount_category
FROM store_rank sr
WHERE sr.sales_rank <= 5
ORDER BY sr.d_year, sr.d_month_seq, sr.sales_rank
