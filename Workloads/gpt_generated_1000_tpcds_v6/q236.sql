WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d_sales.d_year,
        d_sales.d_qoy,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        COUNT(*) AS txn_count,
        ROW_NUMBER() OVER (PARTITION BY d_sales.d_year, d_sales.d_qoy ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rnk_year_qoy
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sales.d_holiday = 'N'
      AND d_sales.d_qoy IN (1, 2, 3, 4)
      AND p.p_channel_radio = 'N'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_event = 'Y'
            AND p2.p_response_target > 10
      )
    GROUP BY p.p_promo_sk, p.p_promo_name, d_sales.d_year, d_sales.d_qoy
)
SELECT
    p_promo_sk,
    p_promo_name,
    d_year,
    d_qoy,
    total_net_paid,
    total_ext_sales,
    txn_count,
    rnk_year_qoy
FROM promo_sales
WHERE rnk_year_qoy <= 10
ORDER BY d_year DESC, d_qoy, rnk_year_qoy
LIMIT 100
