WITH cs_part AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                               AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND c.c_birth_country = 'KOREA'
      AND i.i_color = 'RED'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND cr.cr_return_tax > 50
    GROUP BY d.d_year, i.i_category, p.p_promo_name
),
ws_part AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        CAST(0 AS decimal(7,2)) AS total_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2002
      AND w.web_country = 'USA'
      AND i.i_brand = 'Brand#23'
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, i.i_category, p.p_promo_name
)
SELECT
    year,
    category,
    promo_name,
    SUM(total_sales) AS total_sales,
    SUM(order_cnt) AS total_orders,
    AVG(avg_discount) AS avg_discount,
    SUM(total_returns) AS total_returns
FROM (
    SELECT * FROM cs_part
    UNION ALL
    SELECT * FROM ws_part
) combined
GROUP BY year, category, promo_name
ORDER BY total_sales DESC
LIMIT 100
