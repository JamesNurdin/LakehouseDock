WITH joined_data AS (
    SELECT
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_rec_start_date,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_city,
        s.s_store_sk,
        s.s_state,
        s.s_market_id,
        r.r_reason_desc,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        cs.cs_net_profit,
        cc.cc_state AS cc_state,
        cp.cp_type,
        sm.sm_type,
        p.p_cost,
        p.p_discount_active,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        ws.ws_net_profit
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
),
subquery_one AS (
    SELECT
        s_state,
        r_reason_desc,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
    FROM joined_data
    WHERE s_market_id = 3
      AND i_brand = 'BrandX'
      AND ca_state = 'CA'
      AND p_discount_active = 'Y'
      AND sm_type = 'AIR'
      AND i_rec_start_date >= DATE '2000-01-01'
    GROUP BY s_state, r_reason_desc
),
subquery_two AS (
    SELECT
        s_state,
        r_reason_desc,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'N') AS avg_inactive_promo_cost
    FROM joined_data
    WHERE s_market_id = 7
      AND i_brand = 'BrandY'
      AND ca_state = 'TX'
      AND p_discount_active = 'N'
      AND sm_type = 'GROUND'
      AND i_rec_start_date < DATE '2000-01-01'
    GROUP BY s_state, r_reason_desc
)
SELECT *
FROM (
    SELECT * FROM subquery_one
    UNION ALL
    SELECT * FROM subquery_two
) AS combined
ORDER BY total_catalog_sales DESC
LIMIT 100
