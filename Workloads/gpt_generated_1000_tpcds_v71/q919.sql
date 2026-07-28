WITH
    sale_date AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_customer_sk,
            ss.ss_ext_sales_price,
            ss.ss_ticket_number,
            ss.ss_quantity,
            ss.ss_net_profit
        FROM store_sales ss
    ),
    customer_info AS (
        SELECT
            c.c_customer_sk,
            c.c_preferred_cust_flag,
            c.c_first_shipto_date_sk,
            c.c_first_sales_date_sk
        FROM customer c
    ),
    brand_sales AS (
        SELECT
            i1.i_brand,
            d_sale.d_quarter_name,
            c_info.c_preferred_cust_flag,
            SUM(sale.ss_ext_sales_price) AS total_sales,
            AVG(inv1.inv_quantity_on_hand) AS avg_qty_on_hand,
            COUNT(DISTINCT sale.ss_ticket_number) AS num_transactions
        FROM sale_date sale
        JOIN date_dim d_sale
            ON sale.ss_sold_date_sk = d_sale.d_date_sk
        JOIN item i1
            ON sale.ss_item_sk = i1.i_item_sk
        JOIN customer_info c_info
            ON sale.ss_customer_sk = c_info.c_customer_sk
        JOIN date_dim d_ship
            ON c_info.c_first_shipto_date_sk = d_ship.d_date_sk
        JOIN date_dim d_first_sales
            ON c_info.c_first_sales_date_sk = d_first_sales.d_date_sk
        JOIN inventory inv1
            ON inv1.inv_date_sk = d_sale.d_date_sk
            AND inv1.inv_item_sk = i1.i_item_sk
        JOIN inventory inv2
            ON inv2.inv_date_sk = d_first_sales.d_date_sk
            AND inv2.inv_item_sk = i1.i_item_sk
        JOIN item i2
            ON inv2.inv_item_sk = i2.i_item_sk
        JOIN date_dim d_inv
            ON inv2.inv_date_sk = d_inv.d_date_sk
        WHERE EXISTS (
            SELECT 1
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c_info.c_customer_sk
              AND ss2.ss_ext_sales_price > 1000
        )
        GROUP BY
            i1.i_brand,
            d_sale.d_quarter_name,
            c_info.c_preferred_cust_flag
    )
SELECT
    i_brand,
    d_quarter_name,
    c_preferred_cust_flag,
    total_sales,
    avg_qty_on_hand,
    num_transactions
FROM brand_sales
WHERE total_sales > 50000
ORDER BY total_sales DESC
