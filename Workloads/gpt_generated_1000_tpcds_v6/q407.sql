WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        hd.hd_buy_potential AS buy_potential,
        ib.ib_lower_bound AS income_lower_bound,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        AVG(ss.ss_net_paid_inc_tax) AS avg_net_paid,
        MIN(ss.ss_net_paid_inc_tax) AS min_net_paid,
        MAX(ss.ss_net_paid_inc_tax) AS max_net_paid
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_category_id = 4
      AND ib.ib_lower_bound >= 30000
      AND ss.ss_net_paid_inc_tax > 1000
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_item_sk = i.i_item_sk
            AND ss2.ss_quantity > 5
      )
    GROUP BY i.i_category, i.i_brand, hd.hd_buy_potential, ib.ib_lower_bound
)
SELECT
    category,
    brand,
    buy_potential,
    income_lower_bound,
    sales_cnt,
    total_net_paid,
    avg_net_paid,
    min_net_paid,
    max_net_paid,
    SUM(total_net_paid) OVER (PARTITION BY category ORDER BY brand) AS category_running_total,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
