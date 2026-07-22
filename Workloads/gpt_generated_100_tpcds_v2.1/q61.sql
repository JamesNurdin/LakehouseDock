WITH sales_agg AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_city AS s_city,
        i.i_category AS i_category,
        d_sold.d_year AS d_year,
        sm.sm_type AS sm_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_net_profit) AS max_profit,
        MIN(i.i_current_price) AS min_price
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
        AND cp.cp_end_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_class_id = 5
      AND ib.ib_upper_bound >= 100000
      AND s.s_state = 'CA'
      AND ws.ws_quantity >= 2
    GROUP BY
        s.s_store_id,
        s.s_city,
        i.i_category,
        d_sold.d_year,
        sm.sm_type
)
SELECT
    s_store_id,
    s_city,
    i_category,
    d_year,
    sm_type,
    total_sales,
    total_qty,
    avg_discount,
    order_count,
    max_profit,
    min_price,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
