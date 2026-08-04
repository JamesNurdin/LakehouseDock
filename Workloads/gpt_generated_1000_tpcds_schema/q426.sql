WITH
    sales_right AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            d.d_date AS sold_date,
            ws.ws_bill_customer_sk,
            c.c_customer_id,
            c.c_salutation,
            ws.ws_web_site_sk,
            site.web_name,
            ws.ws_web_page_sk,
            wp.wp_url,
            ws.ws_net_profit,
            ws.ws_ext_sales_price,
            ws.ws_quantity
        FROM date_dim d
        RIGHT OUTER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE d.d_year = 2000
          AND site.web_country = 'United States'
          AND c.c_salutation = 'Mr.'
          AND wp.wp_image_count >= 3
          AND ws.ws_ext_sales_price > 1000
    ),
    page_returns_full AS (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_url,
            wp.wp_image_count,
            wr.wr_order_number,
            wr.wr_return_amt,
            wr.wr_returned_date_sk,
            d_ret.d_date AS return_date,
            wr.wr_refunded_customer_sk
        FROM web_page wp
        FULL OUTER JOIN web_returns wr ON wp.wp_web_page_sk = wr.wr_web_page_sk
        LEFT JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    ),
    union_orders AS (
        SELECT ws_order_number AS order_number FROM sales_right
        UNION
        SELECT wr_order_number AS order_number FROM page_returns_full
    ),
    except_orders AS (
        SELECT ws_order_number FROM sales_right
        EXCEPT
        SELECT wr_order_number FROM page_returns_full
    ),
    intersect_customers AS (
        SELECT ws_bill_customer_sk AS customer_sk FROM sales_right
        INTERSECT
        SELECT wr_refunded_customer_sk FROM web_returns
    ),
    filtered_sales AS (
        SELECT
            sr.ws_order_number,
            sr.c_customer_id,
            sr.c_salutation,
            sr.sold_date,
            sr.web_name,
            sr.wp_url,
            sr.ws_net_profit,
            sr.ws_ext_sales_price,
            sr.ws_quantity,
            ROW_NUMBER() OVER (PARTITION BY sr.c_customer_id ORDER BY sr.ws_net_profit DESC) AS rn_profit
        FROM sales_right sr
        WHERE sr.ws_order_number IN (SELECT order_number FROM union_orders)
          AND sr.ws_bill_customer_sk IN (SELECT customer_sk FROM intersect_customers)
    )
SELECT
    fs.c_customer_id,
    fs.c_salutation,
    fs.sold_date,
    fs.web_name,
    fs.wp_url,
    fs.ws_ext_sales_price,
    fs.ws_net_profit,
    fs.ws_quantity,
    DENSE_RANK() OVER (ORDER BY fs.ws_net_profit DESC) AS profit_rank,
    CASE
        WHEN fs.rn_profit = 1 THEN 'Top Profit Order'
        ELSE 'Other Order'
    END AS order_category
FROM filtered_sales fs
WHERE fs.rn_profit <= 5
ORDER BY profit_rank, fs.c_customer_id
LIMIT 100
