/* goal: Identify top‑selling brands per California store for the year 2002, accounting for sales, returns and inventory on hand, and rank the brands within each store by net sales */
WITH base AS (
    SELECT
        s.s_store_name,
        i.i_brand,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON ss.ss_item_sk = cr.cr_item_sk
        AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        AND d.d_date_sk = inv.inv_date_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND p.p_purpose = 'Unknown'
    GROUP BY ROLLUP (s.s_store_name, i.i_brand, d.d_year)
)
SELECT
    s_store_name,
    i_brand,
    d_year,
    total_sales,
    total_returns,
    total_inventory,
    (total_sales - total_returns) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY (total_sales - total_returns) DESC) AS sales_rank
FROM base
ORDER BY net_sales DESC
LIMIT 100
