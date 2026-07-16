WITH agg AS (
    SELECT
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        s.s_market_desc AS market_desc,
        hd.hd_buy_potential AS buy_potential,
        hd.hd_income_band_sk AS income_band,
        wp.wp_type AS page_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_days,
        AVG(date_diff('day', d_creation.d_date, d_access.d_date)) AS avg_page_age_days,
        AVG(hd_ship.hd_vehicle_count) AS avg_ship_vehicle_count
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE s.s_state = 'CA'
      AND d_sold.d_year BETWEEN 2000 AND 2002
      AND wp.wp_type IN ('product', 'category')
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_market_desc,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        wp.wp_type
)
SELECT
    sold_year,
    sold_month,
    market_desc,
    buy_potential,
    income_band,
    page_type,
    order_cnt,
    total_sales,
    total_profit,
    avg_coupon,
    avg_shipping_days,
    avg_page_age_days,
    avg_ship_vehicle_count,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
