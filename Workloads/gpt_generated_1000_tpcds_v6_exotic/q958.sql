WITH filtered AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_ext_wholesale_cost,
        ws.ws_wholesale_cost,
        ws.ws_ext_ship_cost,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        wp.wp_type,
        wp.wp_rec_start_date,
        wp.wp_max_ad_count
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_rec_start_date <= DATE '2001-12-31'
      AND wp.wp_max_ad_count BETWEEN 0 AND 3
      AND ws.ws_ext_wholesale_cost > 1500.00
      AND ws.ws_wholesale_cost < 80.00
      AND ws.ws_ext_ship_cost BETWEEN 10.00 AND 2000.00
      AND ws.ws_quantity >= 5
      AND ws.ws_net_paid > 2000.00
),
agg AS (
    SELECT
        f.wp_type,
        SUM(f.ws_net_profit) AS total_profit,
        COUNT(DISTINCT f.ws_order_number) AS distinct_orders,
        SUM(f.ws_ext_sales_price) AS total_sales,
        AVG(f.ws_ext_discount_amt) AS avg_discount,
        MIN(f.ws_wholesale_cost) AS min_wholesale_cost,
        MAX(f.ws_wholesale_cost) AS max_wholesale_cost
    FROM filtered f
    GROUP BY f.wp_type
)
SELECT
    agg.wp_type,
    CASE
        WHEN agg.total_profit > 50000 THEN 'High Profit'
        WHEN agg.total_profit BETWEEN 10000 AND 50000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    agg.distinct_orders,
    agg.total_sales,
    agg.avg_discount,
    agg.min_wholesale_cost,
    agg.max_wholesale_cost
FROM agg
ORDER BY agg.total_sales DESC
LIMIT 100
