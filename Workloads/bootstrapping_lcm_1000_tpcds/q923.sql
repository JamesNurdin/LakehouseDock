WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year AS sold_year,
        d_sold.d_quarter_name AS sold_quarter,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        SUM(CASE WHEN d_sold.d_quarter_seq <> d_ship.d_quarter_seq THEN 1 ELSE 0 END) AS cross_quarter_shipments
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2022
      AND ws.ws_net_profit > 0
      AND wp.wp_type IS NOT NULL
      AND d_page_access.d_date >= DATE '2022-01-01'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_quarter_name,
        hd_bill.hd_income_band_sk,
        hd_ship.hd_income_band_sk
)
SELECT
    s_store_id,
    s_store_name,
    sold_year,
    sold_quarter,
    CASE
        WHEN bill_income_band >= 8 THEN 'High Income'
        WHEN bill_income_band >= 4 THEN 'Medium Income'
        ELSE 'Low Income'
    END AS buyer_income_category,
    CASE
        WHEN ship_income_band >= 8 THEN 'High Income'
        WHEN ship_income_band >= 4 THEN 'Medium Income'
        ELSE 'Low Income'
    END AS shipper_income_category,
    total_net_profit,
    total_sales,
    total_discount,
    avg_sales_price,
    distinct_orders,
    distinct_pages,
    cross_quarter_shipments,
    total_net_profit / NULLIF(total_sales, 0) AS profit_margin,
    RANK() OVER (PARTITION BY sold_year, sold_quarter ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
