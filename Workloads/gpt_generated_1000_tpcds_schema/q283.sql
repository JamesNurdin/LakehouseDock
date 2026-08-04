WITH base AS (
    SELECT
        d.d_year,
        cp.cp_department,
        sm.sm_carrier,
        sm.sm_code,
        p.p_discount_active,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state,
        hd.hd_buy_potential,
        cs.cs_order_number,
        cs.cs_net_paid,
        ws.ws_sales_price,
        p.p_cost
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
                                 AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s ON s.s_store_sk = ss.ss_store_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON p.p_promo_sk = cs.cs_promo_sk
                             AND p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                              AND ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.reason r ON r.r_reason_sk = cr.cr_reason_sk
    JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN tpcds.income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
)
SELECT
    d_year,
    cp_department,
    sm_carrier,
    sm_code,
    hd_buy_potential,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(ws_sales_price) AS avg_ws_price,
    MIN(p_cost) AS min_promo_cost,
    MAX(ib_upper_bound) AS max_income_upper
FROM base
WHERE d_year = 2001
  AND cp_department = 'Sports'
  AND sm_code = 'AIR'
  AND p_discount_active = 'Y'
  AND ib_lower_bound >= 5000
  AND ca_state = 'CA'
  AND cs_order_number NOT IN (SELECT cr2.cr_order_number FROM tpcds.catalog_returns cr2)
GROUP BY d_year, cp_department, sm_carrier, sm_code, hd_buy_potential

UNION DISTINCT

SELECT
    d_year,
    cp_department,
    sm_carrier,
    sm_code,
    hd_buy_potential,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(ws_sales_price) AS avg_ws_price,
    MIN(p_cost) AS min_promo_cost,
    MAX(ib_upper_bound) AS max_income_upper
FROM base
WHERE d_year = 2002
  AND cp_department = 'Books'
  AND sm_code = 'SEA'
  AND p_discount_active = 'N'
  AND ib_lower_bound >= 2000
  AND ca_state = 'NY'
  AND cs_order_number NOT IN (SELECT cr3.cr_order_number FROM tpcds.catalog_returns cr3)
GROUP BY d_year, cp_department, sm_carrier, sm_code, hd_buy_potential

ORDER BY total_net_paid DESC
LIMIT 100
