WITH promo_distinct AS (
        SELECT DISTINCT p.p_promo_sk,
               p.p_promo_name,
               p.p_channel_email
        FROM promotion p
        WHERE p.p_channel_email = 'Y'
    ),
    sales_agg AS (
        SELECT ss.ss_customer_sk,
               ss.ss_promo_sk,
               SUM(ss.ss_ext_sales_price) AS total_sales,
               SUM(ss.ss_net_profit)      AS total_profit,
               COUNT(*)                   AS sales_cnt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE hd.hd_income_band_sk BETWEEN 9 AND 14
          AND ss.ss_quantity > 1
        GROUP BY ss.ss_customer_sk, ss.ss_promo_sk
        HAVING SUM(ss.ss_ext_sales_price) > 1000
    ),
    returns_agg AS (
        SELECT sr.sr_customer_sk,
               SUM(sr.sr_return_amt) AS total_return_amt
        FROM store_returns sr
        GROUP BY sr.sr_customer_sk
    )
SELECT DISTINCT
    c.c_customer_id,
    pd.p_promo_name,
    sa.total_sales,
    sa.total_profit,
    COALESCE(r.total_return_amt, 0)                         AS total_return_amount,
    (sa.total_profit - COALESCE(r.total_return_amt, 0))    AS net_after_returns,
    wp.wp_type,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY (sa.total_profit - COALESCE(r.total_return_amt, 0)) DESC) AS rn,
    RANK()       OVER (ORDER BY (sa.total_profit - COALESCE(r.total_return_amt, 0)) DESC)                AS profit_rank
FROM sales_agg sa
JOIN promo_distinct pd ON sa.ss_promo_sk = pd.p_promo_sk
JOIN customer c        ON sa.ss_customer_sk = c.c_customer_sk
LEFT JOIN returns_agg r ON r.sr_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp   ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_type IS NOT NULL
  AND wp.wp_max_ad_count > 0
GROUP BY c.c_customer_id,
         pd.p_promo_name,
         sa.total_sales,
         sa.total_profit,
         r.total_return_amt,
         wp.wp_type
HAVING (sa.total_profit - COALESCE(r.total_return_amt, 0)) > 500
ORDER BY profit_rank
LIMIT 100
