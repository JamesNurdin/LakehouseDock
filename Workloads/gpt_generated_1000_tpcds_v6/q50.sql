WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > (
        SELECT avg(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
    )
)
SELECT
    dd_sold.d_year,
    dd_sold.d_month_seq,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cust_bill.c_customer_id   AS bill_customer_id,
    cust_ship.c_customer_id   AS ship_customer_id,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    SUM(fs.cs_net_profit)      AS total_profit,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    RANK() OVER (PARTITION BY dd_sold.d_year, dd_sold.d_month_seq ORDER BY SUM(fs.cs_ext_sales_price) DESC) AS sales_rank
FROM filtered_sales fs
-- join for the sold date
JOIN date_dim dd_sold ON fs.cs_sold_date_sk = dd_sold.d_date_sk
-- join for the ship date
JOIN date_dim dd_ship ON fs.cs_ship_date_sk = dd_ship.d_date_sk
-- billing customer
JOIN customer cust_bill ON fs.cs_bill_customer_sk = cust_bill.c_customer_sk
-- shipping customer
JOIN customer cust_ship ON fs.cs_ship_customer_sk = cust_ship.c_customer_sk
-- item dimension (first usage)
JOIN item i ON fs.cs_item_sk = i.i_item_sk
-- promotion dimension
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
-- promotion start date
JOIN date_dim dd_promo_start ON p.p_start_date_sk = dd_promo_start.d_date_sk
-- promotion end date
JOIN date_dim dd_promo_end ON p.p_end_date_sk = dd_promo_end.d_date_sk
-- web site dimension (open date)
JOIN web_site ws ON ws.web_open_date_sk = dd_sold.d_date_sk
-- web site close date
JOIN date_dim dd_web_close ON ws.web_close_date_sk = dd_web_close.d_date_sk
-- second item alias for promotion‑item relationship
JOIN item i2 ON p.p_item_sk = i2.i_item_sk
WHERE dd_sold.d_year = 2001
  AND i.i_color = 'BLUE'
GROUP BY GROUPING SETS (
    (dd_sold.d_year, dd_sold.d_month_seq, i.i_item_id, i.i_product_name, p.p_promo_name, cust_bill.c_customer_id, cust_ship.c_customer_id),
    (dd_sold.d_year, dd_sold.d_month_seq),
    ()
)
HAVING SUM(fs.cs_ext_sales_price) > 1000
ORDER BY dd_sold.d_year,
         dd_sold.d_month_seq,
         total_sales DESC
LIMIT 100
