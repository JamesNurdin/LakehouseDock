WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year,
        cd.cd_gender,
        ca.ca_state,
        s.s_store_sk,
        s.s_state,
        p.p_promo_sk,
        p.p_promo_name,
        inv.inv_quantity_on_hand,
        sm.sm_ship_mode_sk,
        sm.sm_code,
        cp.cp_department,
        cr.cr_return_amount,
        ws.ws_ext_tax,
        ws.ws_ext_discount_amt,
        ws.ws_order_number,
        wsite.web_site_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
)
SELECT
    s_state,
    p_promo_name,
    cp_department,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(ss_quantity * i_current_price) AS total_sales_amount,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ws_ext_discount_amt) AS avg_discount,
    MIN(i_current_price) AS min_price,
    MAX(i_current_price) AS max_price,
    SUM(CASE WHEN i_brand = 'BrandX' THEN 1 ELSE 0 END) AS brandx_count
FROM sales_base
WHERE i_current_price BETWEEN 50 AND 200
  AND c_birth_year = 1975
  AND s_state = 'CA'
  AND sm_code = 'AIR'
  AND cp_department = 'DEPARTMENT'
  AND ws_ext_tax > 20.00
GROUP BY s_state, p_promo_name, cp_department
ORDER BY total_sales_amount DESC
LIMIT 100
