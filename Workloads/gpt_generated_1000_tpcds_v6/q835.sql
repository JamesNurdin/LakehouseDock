WITH base AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        i.i_brand,
        ca.ca_state,
        ca.ca_country,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        p_ss.p_discount_active,
        sm.sm_code,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_net_profit AS store_net_profit,
        sr.sr_return_amt AS store_return_amt,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_net_profit AS web_net_profit,
        wp.wp_type,
        web.web_name,
        wr.wr_return_amt AS web_return_amt,
        ws.ws_sold_date_sk
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 100
      AND ca.ca_state = 'CA'
      AND hd.hd_vehicle_count >= 1
      AND ib.ib_upper_bound = 130000
      AND sm.sm_code = 'AIR'
      AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND p_ss.p_discount_active = 'Y'
      AND w.w_warehouse_sq_ft > 100000
      AND i.i_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 500)
),
aggregated AS (
    SELECT
        i_category,
        ca_state,
        sm_code,
        w_warehouse_name,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
        SUM(store_net_paid) AS total_store_sales,
        SUM(web_net_paid) AS total_web_sales,
        SUM(store_return_amt) AS total_store_returns,
        SUM(web_return_amt) AS total_web_returns,
        AVG(i_current_price) AS avg_item_price,
        MIN(store_net_paid) AS min_store_sale,
        MAX(web_net_paid) AS max_web_sale
    FROM base
    GROUP BY i_category, ca_state, sm_code, w_warehouse_name
)
SELECT
    a.i_category,
    a.ca_state,
    a.sm_code,
    a.w_warehouse_name,
    a.distinct_customers,
    a.total_store_sales,
    a.total_web_sales,
    a.total_store_returns,
    a.total_web_returns,
    a.avg_item_price,
    a.min_store_sale,
    a.max_web_sale,
    RANK() OVER (ORDER BY a.total_store_sales DESC) AS sales_rank,
    SUM(a.total_store_sales) OVER (PARTITION BY a.ca_state) AS state_total_store_sales
FROM aggregated a
ORDER BY a.total_store_sales DESC
LIMIT 100
