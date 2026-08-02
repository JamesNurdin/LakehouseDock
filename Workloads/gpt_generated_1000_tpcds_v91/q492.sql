WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        d1.d_year AS cs_sold_year,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        sm.sm_carrier,
        w.w_state,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_sold_date_sk,
        d2.d_year AS ss_sold_year,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        d3.d_year AS sr_return_year,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        d4.d_year AS ws_sold_year,
        wp.wp_url,
        site.web_city,
        site.web_state,
        time.t_hour,
        wp2.wp_url AS wr_page_url,
        ROW_NUMBER() OVER (PARTITION BY d1.d_year ORDER BY cs.cs_net_paid DESC) AS rn_cs_year,
        CASE WHEN cs.cs_net_paid > (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2) THEN 1 ELSE 0 END AS net_paid_above_max
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d3 ON sr.sr_returned_date_sk = d3.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d4 ON ws.ws_sold_date_sk = d4.d_date_sk
    JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN time_dim time ON ws.ws_sold_time_sk = time.t_time_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d5 ON wr.wr_returned_date_sk = d5.d_date_sk
    JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    WHERE
        d1.d_year = 1999
        AND i.i_brand = 'Brand#23'
        AND sm.sm_carrier = 'DHL'
        AND w.w_state = 'CA'
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_upper_bound < 60000
        AND ss.ss_quantity > 2
        AND ws.ws_net_profit > 0
        AND time.t_hour BETWEEN 8 AND 18
        AND wp.wp_type = 'Home'
),
order_diff AS (
    SELECT ws.ws_order_number AS order_num
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
    EXCEPT
    SELECT sr.sr_ticket_number AS order_num
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
agg AS (
    SELECT
        i.i_brand,
        d1.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        AVG(cs.cs_net_paid) AS avg_net_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    GROUP BY i.i_brand, d1.d_year
    HAVING SUM(cs.cs_ext_sales_price) > 100000
)
SELECT
    a.i_brand,
    a.d_year,
    a.total_sales,
    a.num_orders,
    a.avg_net_paid,
    b.rn_cs_year,
    b.net_paid_above_max
FROM agg a
JOIN base b
    ON b.i_brand = a.i_brand
    AND b.cs_sold_year = a.d_year
WHERE b.ws_order_number IN (SELECT order_num FROM order_diff)
ORDER BY a.total_sales DESC, a.d_year
LIMIT 100
