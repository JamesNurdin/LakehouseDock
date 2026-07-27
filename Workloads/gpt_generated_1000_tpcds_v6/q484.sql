WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        ib.ib_lower_bound AS income_low,
        ib.ib_upper_bound AS income_high,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND d.d_holiday = 'N'
      AND i.i_units = 'Case'
      AND ib.ib_lower_bound >= 0
      AND ib.ib_upper_bound <= 150000
      AND p.p_discount_active = 'Y'
      AND i.i_category_id IS NOT NULL
    GROUP BY d.d_year, i.i_category, p.p_promo_name, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    year,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_qty) AS sum_total_qty,
    COUNT(*) AS groups_count
FROM sales_agg
GROUP BY year
HAVING AVG(total_sales) > 1000
ORDER BY avg_total_sales DESC
LIMIT 100
