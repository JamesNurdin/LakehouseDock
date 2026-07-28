WITH sales_returns AS (
    SELECT
        s.s_store_sk,
        s.s_store_name AS store_name,
        d.d_year AS year,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_market_manager = 'John Sizemore'
      AND ss.ss_net_paid_inc_tax > 500.00
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
)
SELECT
    sr.store_name,
    sr.year,
    sr.total_sales,
    sr.total_returns,
    sr.total_sales - sr.total_returns AS net_sales,
    sr.total_quantity_sold,
    sr.total_inventory_qty,
    (sr.total_sales - sr.total_returns) / NULLIF(sr.total_quantity_sold, 0) AS avg_sale_per_item
FROM sales_returns sr
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    JOIN date_dim d2
        ON wp.wp_creation_date_sk = d2.d_date_sk
    WHERE d2.d_year = sr.year
      AND wp.wp_type = 'product'
)
ORDER BY sr.total_sales DESC
LIMIT 100
