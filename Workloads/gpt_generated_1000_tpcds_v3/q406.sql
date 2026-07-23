WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        i.i_brand,
        i.i_color,
        i.i_units,
        i.i_manufact_id,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END AS income_category
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_sales_price > 20.00
      AND ss.ss_quantity >= 2
      AND i.i_units = 'Box'
      AND ib.ib_upper_bound >= 50000
      AND hd.hd_vehicle_count >= 2
      AND i.i_manufact_id IN (630, 167)
)
SELECT
    income_category,
    i_brand,
    i_color,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_quantity) AS max_quantity,
    CASE WHEN SUM(ss_ext_sales_price) > 100000 THEN 'Big Spender' ELSE 'Regular' END AS spender_category
FROM filtered_sales
GROUP BY income_category, i_brand, i_color
ORDER BY total_sales DESC
LIMIT 100
