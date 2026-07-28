WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_list_price,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_category,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 60000
      AND ws.ws_warehouse_sk IN (1, 4, 5)
      AND ws.ws_ext_list_price > 1000
),
aggregated AS (
    SELECT
        i_category,
        ib_lower_bound,
        ib_upper_bound,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_sales,
        SUM(ws_net_profit) AS total_profit
    FROM filtered_sales
    GROUP BY i_category, ib_lower_bound, ib_upper_bound
)
SELECT
    i_category,
    CONCAT(CAST(ib_lower_bound AS varchar), '-', CAST(ib_upper_bound AS varchar)) AS income_band_range,
    total_sales,
    avg_sales,
    total_profit,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 10
