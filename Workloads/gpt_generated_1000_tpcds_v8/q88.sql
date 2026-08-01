WITH agg AS (
    SELECT
        p.p_promo_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d_sales.d_year AS sales_year,
        wp.wp_type,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        MAX(ss.ss_net_profit) AS max_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr ON hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page ON wp.wp_creation_date_sk = d_page.d_date_sk
    WHERE d_sales.d_year = 2002
      AND ib.ib_upper_bound <= 80000
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound < (
          SELECT MAX(ib2.ib_upper_bound)
          FROM income_band ib2
      ) - 1000
    GROUP BY p.p_promo_name, ib.ib_lower_bound, ib.ib_upper_bound, d_sales.d_year, wp.wp_type
)
SELECT
    agg.p_promo_name,
    agg.ib_lower_bound,
    agg.ib_upper_bound,
    agg.sales_year,
    agg.wp_type,
    agg.total_quantity,
    agg.total_sales,
    agg.total_return_qty,
    agg.total_net_loss,
    agg.avg_discount,
    agg.max_profit,
    agg.profit_category,
    RANK() OVER (ORDER BY agg.total_sales DESC) AS sales_rank,
    SUM(agg.total_sales) OVER (
        PARTITION BY agg.sales_year
        ORDER BY agg.total_sales
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_year
FROM agg
ORDER BY agg.total_sales DESC
LIMIT 100
