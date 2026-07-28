WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS s_store_sk,
        d.d_year AS sales_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_count,
        AVG(ss.ss_coupon_amt) AS avg_coupon
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'High'
      AND p.p_response_target = 1
      AND d.d_year = 2001
      AND t.t_hour BETWEEN 10 AND 15
      AND ss.ss_coupon_amt > 500
    GROUP BY ss.ss_store_sk, d.d_year
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS s_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_store_sk
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    sa.total_sales,
    sa.total_profit,
    sa.sales_count,
    sa.avg_coupon,
    ra.total_return_amt,
    ra.return_count,
    (sa.total_sales - COALESCE(ra.total_return_amt, 0)) AS net_sales
FROM sales_agg sa
JOIN store s ON sa.s_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra ON s.s_store_sk = ra.s_store_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_store_sk = s.s_store_sk
      AND r.r_reason_desc = 'Damaged'
)
ORDER BY net_sales DESC
LIMIT 100
