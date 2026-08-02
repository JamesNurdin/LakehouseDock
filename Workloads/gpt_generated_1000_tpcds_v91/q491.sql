WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid_inc_tax,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        p.p_promo_name,
        cc.cc_call_center_id,
        cc.cc_state,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        w.w_city,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state AS ca_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        wp.wp_url,
        web_site.web_name,
        c_ws.c_customer_id AS c_ws_customer_id,
        sm_ws.sm_ship_mode_id AS ws_ship_mode_id,
        w_ws.w_warehouse_id AS ws_warehouse_id,
        p_ws.p_promo_name AS ws_promo_name,
        hd_ws.hd_income_band_sk AS ws_hd_income_band_sk,
        ib_ws.ib_lower_bound AS ws_ib_lower_bound,
        ca_ws.ca_state AS ws_ca_state,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        r_wr.r_reason_desc AS wr_reason_desc,
        hd_wr.hd_income_band_sk AS wr_hd_income_band_sk,
        ib_wr.ib_lower_bound AS wr_ib_lower_bound,
        c_wr_refund.c_customer_id AS wr_refund_customer_id,
        ca_wr_refund.ca_state AS wr_refund_address_state,
        ARRAY[CAST(cs.cs_quantity AS decimal(7,2)), cs.cs_ext_discount_amt] AS metrics
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
        LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        LEFT JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
        LEFT JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
        LEFT JOIN income_band ib_ws ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
        LEFT JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
        LEFT JOIN income_band ib_wr ON hd_wr.hd_income_band_sk = ib_wr.ib_income_band_sk
        LEFT JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
        LEFT JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    WHERE
        cs.cs_quantity > 5
        AND cs.cs_ext_discount_amt > 100
        AND i.i_product_name LIKE '%a%'
        AND cc.cc_state = 'CA'
        AND w.w_city = 'SAN FRANCISCO'
        AND ib.ib_lower_bound >= 50000
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450600
),
expanded AS (
    SELECT
        b.*, 
        m.metric_value,
        m.metric_pos
    FROM base b
    CROSS JOIN UNNEST(b.metrics) WITH ORDINALITY AS m(metric_value, metric_pos)
)
SELECT
    e.cs_order_number AS order_number,
    e.i_item_id,
    e.cs_quantity,
    e.metric_value,
    e.metric_pos,
    e.cs_net_paid_inc_tax AS revenue,
    e.c_customer_id AS customer_id,
    RANK() OVER (PARTITION BY e.i_item_id ORDER BY e.cs_net_paid_inc_tax DESC) AS revenue_rank,
    'catalog' AS channel
FROM expanded e
WHERE e.cs_order_number IS NOT NULL
UNION ALL
SELECT
    e.ws_order_number AS order_number,
    e.i_item_id,
    e.ws_quantity AS quantity,
    e.metric_value,
    e.metric_pos,
    e.ws_net_paid AS revenue,
    e.c_ws_customer_id AS customer_id,
    RANK() OVER (PARTITION BY e.i_item_id ORDER BY e.ws_net_paid DESC) AS revenue_rank,
    'web' AS channel
FROM expanded e
WHERE e.ws_order_number IS NOT NULL
ORDER BY revenue_rank, metric_pos
LIMIT 100
