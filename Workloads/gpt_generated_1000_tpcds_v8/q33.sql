/* goal: Identify average catalog sales amount per department for the year 2001, focusing on books sold via air shipping with direct mail promotions, and enrich the result with web page, return and demographic context. */
WITH sales_agg AS (
    SELECT
        d.d_date,
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        (
            SELECT COUNT(*)
            FROM store_returns sr2
            WHERE sr2.sr_returned_date_sk = d.d_date_sk
        ) AS returns_on_date
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Books'
      AND wp.wp_type = 'Content'
      AND ca_sr.ca_state = 'CA'
    GROUP BY d.d_date, cp.cp_department, sm.sm_type, d.d_date_sk
)
SELECT
    department,
    AVG(total_sales) AS avg_sales,
    SUM(order_cnt) AS total_orders,
    SUM(returns_on_date) AS total_returns
FROM sales_agg
GROUP BY department
HAVING AVG(total_sales) > 10000
ORDER BY avg_sales DESC
LIMIT 100
