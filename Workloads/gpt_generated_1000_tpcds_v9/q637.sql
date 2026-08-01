WITH
    base AS (
        SELECT
            i_cs.i_item_id,
            i_cs.i_product_name,
            d_cs_sold.d_year AS sale_year,
            d_cs_ship.d_year AS ship_year,
            w.web_name,
            cs.cs_net_paid,
            cs.cs_ext_sales_price,
            cs.cs_ext_discount_amt,
            ss.ss_net_paid,
            ss.ss_ext_sales_price
        FROM catalog_sales cs
        JOIN date_dim d_cs_sold
            ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
        JOIN date_dim d_cs_ship
            ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
        JOIN time_dim t_cs_sold
            ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
        JOIN item i_cs
            ON cs.cs_item_sk = i_cs.i_item_sk
        JOIN store_sales ss
            ON ss.ss_item_sk = i_cs.i_item_sk
        JOIN date_dim d_ss_sold
            ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
        JOIN time_dim t_ss_sold
            ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
        JOIN item i_ss
            ON ss.ss_item_sk = i_ss.i_item_sk
        LEFT JOIN web_site w
            ON w.web_open_date_sk = d_cs_sold.d_date_sk
               AND w.web_close_date_sk = d_cs_ship.d_date_sk
        WHERE d_cs_sold.d_year = 2001
    )
SELECT
    i_item_id AS item_id,
    i_product_name AS product_name,
    sale_year,
    ship_year,
    web_name,
    SUM(cs_net_paid + ss_net_paid) AS total_net_paid,
    SUM(cs_ext_sales_price + ss_ext_sales_price) AS total_sales_price,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    (SELECT AVG(cs2.cs_ext_discount_amt) FROM catalog_sales cs2) AS overall_avg_catalog_discount
FROM base
GROUP BY
    i_item_id,
    i_product_name,
    sale_year,
    ship_year,
    web_name
ORDER BY total_net_paid DESC
LIMIT 100
