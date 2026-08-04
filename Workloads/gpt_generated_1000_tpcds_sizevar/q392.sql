WITH
union_sales AS (
    -- First branch: catalog sales with deep joins, table sampling, and a lateral subquery
    SELECT
        c.c_customer_id,
        d_sold.d_year,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(*) AS order_cnt,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        MIN(s.s_store_name) AS store_name
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN (
            SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
        ) inv ON cs.cs_item_sk = inv.inv_item_sk
               AND inv.inv_date_sk = d_sold.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
        LEFT JOIN LATERAL (
            SELECT cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0) AS discount_ratio
        ) lr ON TRUE
    WHERE
        d_sold.d_year = 2001
    GROUP BY
        c.c_customer_id,
        d_sold.d_year

    UNION DISTINCT

    -- Second branch: web sales, also using a lateral subquery and matching the column list
    SELECT
        c.c_customer_id,
        d_ws.d_year,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(*) AS order_cnt,
        CAST(NULL AS INTEGER) AS total_inventory,
        CAST(NULL AS VARCHAR) AS store_name
    FROM
        web_sales ws
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        LEFT JOIN LATERAL (
            SELECT ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0) AS discount_ratio
        ) lr_ws ON TRUE
    WHERE
        d_ws.d_year = 2001
    GROUP BY
        c.c_customer_id,
        d_ws.d_year
),
intersect_customers AS (
    SELECT us.c_customer_id, us.d_year
    FROM union_sales us
    INTERSECT
    SELECT c.c_customer_id, d_ret.d_year
    FROM catalog_returns cr
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d_ret.d_year = 2001
)
SELECT
    us.c_customer_id,
    us.d_year,
    us.net_paid,
    us.order_cnt,
    us.total_inventory,
    us.store_name
FROM union_sales us
WHERE (us.c_customer_id, us.d_year) IN (SELECT c_customer_id, d_year FROM intersect_customers)
ORDER BY us.net_paid DESC
LIMIT 100
