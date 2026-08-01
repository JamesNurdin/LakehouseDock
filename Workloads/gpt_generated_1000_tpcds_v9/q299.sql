WITH
    sub_a AS (
        SELECT
            d.d_year AS year,
            p.p_promo_name AS promotion_name,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            COUNT(DISTINCT cs.cs_order_number) AS total_orders
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN store s
            ON s.s_closed_date_sk = d.d_date_sk
        JOIN date_dim d_open
            ON cc.cc_open_date_sk = d_open.d_date_sk
        JOIN date_dim d_close
            ON cc.cc_closed_date_sk = d_close.d_date_sk
        GROUP BY d.d_year, p.p_promo_name
    ),
    sub_b AS (
        SELECT
            d2.d_year AS year,
            p2.p_promo_name AS promotion_name,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            COUNT(DISTINCT ws.ws_order_number) AS total_orders
        FROM web_sales ws
        JOIN date_dim d2
            ON ws.ws_sold_date_sk = d2.d_date_sk
        JOIN time_dim t2
            ON ws.ws_sold_time_sk = t2.t_time_sk
        JOIN item i2
            ON ws.ws_item_sk = i2.i_item_sk
        JOIN promotion p2
            ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN customer c2
            ON ws.ws_bill_customer_sk = c2.c_customer_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we
            ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
        LEFT JOIN reason r
            ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN date_dim d_ret
            ON wr.wr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN store s2
            ON s2.s_closed_date_sk = d2.d_date_sk
        GROUP BY d2.d_year, p2.p_promo_name
    ),
    sub_c AS (
        SELECT
            d3.d_year AS year,
            p3.p_promo_name AS promotion_name,
            SUM(cs2.cs_ext_sales_price) AS total_sales,
            COUNT(DISTINCT cs2.cs_order_number) AS total_orders
        FROM catalog_sales cs2
        JOIN date_dim d3
            ON cs2.cs_sold_date_sk = d3.d_date_sk
        JOIN promotion p3
            ON cs2.cs_promo_sk = p3.p_promo_sk
        WHERE d3.d_year BETWEEN 1999 AND 2002
        GROUP BY d3.d_year, p3.p_promo_name
    )
SELECT
    year,
    promotion_name,
    total_sales,
    total_orders
FROM (
    SELECT year, promotion_name, total_sales, total_orders FROM sub_a
    UNION
    SELECT year, promotion_name, total_sales, total_orders FROM sub_b
) AS unioned
INTERSECT
SELECT year, promotion_name, total_sales, total_orders FROM sub_c
LIMIT 100
