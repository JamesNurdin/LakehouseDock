WITH sales_agg AS (
    SELECT
        i.i_item_id,
        sm.sm_carrier,
        sm.sm_code,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        sm.sm_carrier = 'FEDEX'
        AND i.i_item_id = 'AAAAAAAABAAAAAAA'
        AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        i.i_item_id,
        sm.sm_carrier,
        sm.sm_code
),
carrier_stats AS (
    SELECT
        sm_carrier,
        AVG(total_sales) AS avg_sales,
        SUM(total_sales) AS sum_sales
    FROM sales_agg
    GROUP BY sm_carrier
    HAVING AVG(total_sales) > 50000
),
final AS (
    SELECT
        s.i_item_id,
        s.sm_carrier,
        s.sm_code,
        s.total_sales,
        s.total_profit,
        s.order_cnt,
        CASE WHEN s.total_sales > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY s.sm_carrier ORDER BY s.total_sales DESC) AS sales_rank
    FROM sales_agg s
    JOIN carrier_stats cs ON s.sm_carrier = cs.sm_carrier
    WHERE s.total_profit > 0
)
SELECT
    i_item_id,
    sm_carrier,
    sm_code,
    total_sales,
    total_profit,
    order_cnt,
    sales_category,
    sales_rank
FROM final
WHERE sales_rank <= 3
ORDER BY sm_carrier, sales_rank
