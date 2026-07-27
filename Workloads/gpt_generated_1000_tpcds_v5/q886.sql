WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        sm.sm_type,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt ELSE 0 END) AS total_return_amt,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND i.i_current_price BETWEEN 10 AND 100
      AND sm.sm_type = 'AIR'
      AND hd.hd_vehicle_count >= 2
      AND wp.wp_image_count >= 2
    GROUP BY d.d_year, i.i_brand, sm.sm_type, ws.ws_ship_mode_sk
),
with_brand_return AS (
    SELECT
        b.d_year,
        b.i_brand,
        b.sm_type,
        b.ws_ship_mode_sk,
        b.total_sales,
        b.total_profit,
        b.sales_cnt,
        b.total_return_amt,
        b.sales_category,
        (
            SELECT AVG(wr2.wr_return_amt)
            FROM web_returns wr2
            JOIN item i2 ON wr2.wr_item_sk = i2.i_item_sk
            WHERE i2.i_brand = b.i_brand
        ) AS avg_brand_return_amt
    FROM base b
),
final AS (
    SELECT
        d_year,
        i_brand,
        sm_type,
        total_sales,
        total_profit,
        sales_cnt,
        total_return_amt,
        sales_category,
        avg_brand_return_amt,
        total_sales / NULLIF(sales_cnt, 0) AS avg_sales_per_tx,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year
    FROM with_brand_return
    WHERE total_sales > 50000
      AND total_return_amt < 20000
      AND sales_category = 'HIGH'
      AND avg_brand_return_amt < 500
)
SELECT
    d_year,
    i_brand,
    sm_type,
    total_sales,
    total_profit,
    sales_cnt,
    avg_sales_per_tx,
    sales_rank_year,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_year
FROM final
ORDER BY d_year, total_sales DESC
LIMIT 100
