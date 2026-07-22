WITH base AS (
    SELECT
        c.c_customer_id AS c_customer_id,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        d.d_date AS d_date,
        t.t_hour AS t_hour,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        sr.sr_return_amt AS sr_return_amt,
        cr.cr_return_amount AS cr_return_amount,
        COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) - COALESCE(sr.sr_return_amt, 0) - COALESCE(cr.cr_return_amount, 0) AS net_amount
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk AND p.p_promo_sk = ws.ws_promo_sk
    JOIN warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN time_dim t ON t.t_time_sk = ss.ss_sold_time_sk
    WHERE d.d_year = 2001
      AND c.c_birth_country IN ('FIJI', 'CHILE')
      AND ca.ca_location_type = 'apartment'
      AND p.p_discount_active = 'Y'
      AND w.w_warehouse_sq_ft > 50000
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    sub.c_customer_id,
    sub.c_first_name,
    sub.c_last_name,
    sub.d_date,
    sub.t_hour,
    sub.ws_ext_sales_price,
    sub.ss_ext_sales_price,
    sub.sr_return_amt,
    sub.cr_return_amount,
    sub.net_amount,
    sub.rn
FROM (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        d_date,
        t_hour,
        ws_ext_sales_price,
        ss_ext_sales_price,
        sr_return_amt,
        cr_return_amount,
        net_amount,
        ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY net_amount DESC) AS rn
    FROM base
) sub
WHERE sub.rn <= 5
ORDER BY sub.net_amount DESC, sub.c_customer_id
LIMIT 100
