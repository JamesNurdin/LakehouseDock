WITH
    /* Fact joined to promotion with a RIGHT OUTER JOIN (keep promos without sales) */
    sales_promo AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            p.p_promo_id,
            d.d_year,
            i.i_product_name,
            i.i_brand,
            i.i_category,
            w.w_warehouse_name,
            ca.ca_state,
            hd.hd_buy_potential
        FROM catalog_sales cs
        RIGHT OUTER JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    ),
    /* Returns linked to date and item, with extra dim joins */
    returns_data AS (
        SELECT
            cr.cr_order_number,
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            d.d_year AS return_year,
            i.i_product_name,
            ca.ca_state,
            hd.hd_buy_potential
        FROM catalog_returns cr
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i
            ON cr.cr_item_sk = i.i_item_sk
        LEFT JOIN customer_address ca
            ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN household_demographics hd
            ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    ),
    /* Web‑page dates */
    web_page_dates AS (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_url,
            d.d_date AS creation_date
        FROM web_page wp
        JOIN date_dim d
            ON wp.wp_creation_date_sk = d.d_date_sk
    ),
    /* Web‑site opening dates */
    web_site_dates AS (
        SELECT
            ws.web_site_sk,
            ws.web_name,
            d.d_date AS open_date
        FROM web_site ws
        JOIN date_dim d
            ON ws.web_open_date_sk = d.d_date_sk
    ),
    /* Full outer join of page and site on their dates */
    web_page_site_full AS (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_url,
            ws.web_site_sk,
            ws.web_name,
            COALESCE(wp.creation_date, ws.open_date) AS event_date
        FROM web_page_dates wp
        FULL OUTER JOIN web_site_dates ws
            ON wp.creation_date = ws.open_date
    ),
    /* Web returns enriched with the full‑outer‑joined page/site info */
    web_returns_cte AS (
        SELECT
            wr.wr_order_number,
            wr.wr_returned_date_sk,
            wr.wr_item_sk,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            d.d_year AS web_return_year,
            wp.wp_url,
            ws.web_name
        FROM web_returns wr
        JOIN date_dim d
            ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_page_site_full wp_site
            ON wp.wp_web_page_sk = wp_site.wp_web_page_sk
               AND d.d_date = wp_site.event_date
        LEFT JOIN web_site ws
            ON ws.web_site_sk = wp_site.web_site_sk
    ),
    /* Two simple sets of order numbers to intersect */
    orders_in_sales AS (
        SELECT cs_order_number AS order_number
        FROM sales_promo
        WHERE cs_order_number IS NOT NULL
    ),
    orders_in_returns AS (
        SELECT cr_order_number AS order_number
        FROM returns_data
    ),
    common_orders AS (
        SELECT order_number FROM orders_in_sales
        INTERSECT
        SELECT order_number FROM orders_in_returns
    ),
    /* Ranking per year, using UNNEST on product name */
    ranked AS (
        SELECT
            d.d_year,
            i.i_brand,
            SUM(sp.cs_net_paid) AS total_net_paid,
            SUM(sp.cs_net_profit) AS total_net_profit,
            COUNT(DISTINCT sp.cs_order_number) AS distinct_orders,
            ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sp.cs_net_paid) DESC) AS rn
        FROM sales_promo sp
        JOIN common_orders co
            ON sp.cs_order_number = co.order_number
        JOIN date_dim d
            ON sp.cs_sold_date_sk = d.d_date_sk
        JOIN item i
            ON sp.cs_item_sk = i.i_item_sk
        /* Expand the product name into words */
        CROSS JOIN UNNEST(split(i.i_product_name, ' ')) AS t(word)
        WHERE d.d_year BETWEEN 1999 AND 2002
        GROUP BY d.d_year, i.i_brand
        HAVING SUM(sp.cs_net_paid) > 10000
    )
SELECT
    d_year,
    i_brand,
    total_net_paid,
    total_net_profit,
    distinct_orders
FROM ranked
WHERE rn <= 5
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
