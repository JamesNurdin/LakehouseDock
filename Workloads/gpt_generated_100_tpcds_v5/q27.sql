WITH dr AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    dr.d_year,
    i1.i_category,
    i2.i_brand,
    c.c_first_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(*) AS transaction_count
FROM dr
JOIN store_returns sr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN reason r1
    ON sr.sr_reason_sk = r1.r_reason_sk
JOIN item i1
    ON sr.sr_item_sk = i1.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i1.i_item_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = dr.d_date_sk
JOIN item i2
    ON ws.ws_item_sk = i2.i_item_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN reason r2
    ON cr.cr_reason_sk = r2.r_reason_sk
WHERE ws.ws_quantity > 20
GROUP BY dr.d_year, i1.i_category, i2.i_brand, c.c_first_name
ORDER BY total_sales DESC
LIMIT 100
