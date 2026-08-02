WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_upper_bound,
        ib.ib_income_band_sk
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_store_sk IN (34, 56, 350)
      AND ss.ss_wholesale_cost > 10
      AND ib.ib_upper_bound >= 100000
      AND hd.hd_vehicle_count >= 0
      AND NOT EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_item_sk = ss.ss_item_sk
            AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
            AND ss2.ss_quantity > ss.ss_quantity
      )
),

enriched_sales AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_wholesale_cost,
        ss_ext_sales_price,
        ss_net_profit,
        hd_vehicle_count,
        ib_upper_bound,
        CASE WHEN ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_category,
        RANK() OVER (PARTITION BY ib_upper_bound ORDER BY ss_net_profit DESC) AS profit_rank_in_income_band
    FROM filtered_sales
)

SELECT
    ib_upper_bound,
    hd_vehicle_count,
    total_sales,
    total_profit,
    distinct_store_cnt,
    pos_profit_cnt,
    max_profit_rank,
    RANK() OVER (ORDER BY total_profit DESC) AS overall_profit_rank
FROM (
    SELECT
        ib_upper_bound,
        hd_vehicle_count,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_store_sk) AS distinct_store_cnt,
        SUM(CASE WHEN profit_category = 'POS' THEN 1 ELSE 0 END) AS pos_profit_cnt,
        MAX(profit_rank_in_income_band) AS max_profit_rank
    FROM enriched_sales
    GROUP BY GROUPING SETS (
        (ib_upper_bound, hd_vehicle_count),
        (ib_upper_bound),
        ()
    )
    UNION DISTINCT
    SELECT
        ib_upper_bound,
        hd_vehicle_count,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_store_sk) AS distinct_store_cnt,
        SUM(CASE WHEN profit_category = 'POS' THEN 1 ELSE 0 END) AS pos_profit_cnt,
        MAX(profit_rank_in_income_band) AS max_profit_rank
    FROM enriched_sales
    GROUP BY CUBE (ib_upper_bound, hd_vehicle_count)
) AS combined
ORDER BY ib_upper_bound NULLS LAST,
         hd_vehicle_count NULLS LAST,
         total_profit DESC
LIMIT 100
