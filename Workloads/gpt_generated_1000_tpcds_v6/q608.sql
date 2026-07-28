WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        i.i_manufact AS manufact,
        hd.hd_income_band_sk AS income_band_sk,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE hd.hd_dep_count BETWEEN 2 AND 5
      AND hd.hd_buy_potential = '5001-10000'
      AND i.i_manufact = 'callyeingeing'
      AND i.i_class_id IN (1, 6, 10)
      AND inv.inv_quantity_on_hand > 800
    GROUP BY i.i_category, i.i_class, i.i_manufact, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING SUM(ss.ss_ext_sales_price) > 20000
)
SELECT
    category,
    class,
    manufact,
    income_band_sk,
    lower_bound,
    upper_bound,
    total_sales,
    avg_profit,
    sales_cnt,
    total_quantity,
    SUM(total_sales) OVER (PARTITION BY category ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_category,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
