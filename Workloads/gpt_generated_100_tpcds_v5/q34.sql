WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        AVG(p.p_cost) AS avg_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                           AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 1918
      AND cd.cd_gender = 'F'
      AND p.p_cost > 5000
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    s_store_id,
    d_year,
    total_sales,
    total_returns,
    sales_transactions,
    avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM sales_agg) AS overall_avg_sales
FROM sales_agg
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
