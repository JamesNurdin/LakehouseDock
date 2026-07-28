WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_ext_sales_price)                         AS total_sales,
    AVG(ss.ss_sales_price)                             AS avg_sales_price,
    COUNT(DISTINCT c.c_customer_id)                    AS distinct_customers,
    MIN(ss.ss_sales_price)                             AS min_price,
    MAX(ss.ss_sales_price)                             AS max_price,
    SUM(COALESCE(cr.cr_return_quantity, 0))            AS total_catalog_returns,
    SUM(COALESCE(sr.sr_return_quantity, 0))            AS total_store_returns,
    SUM(ia.total_qty_on_hand)                          AS total_inventory_on_hand,
    MAX((SELECT MAX(ib2.ib_upper_bound)
          FROM income_band ib2
          WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk)) AS max_income_upper,
    MAX((SELECT COUNT(DISTINCT wp2.wp_web_page_id)
          FROM web_page wp2
          WHERE wp2.wp_customer_sk = c.c_customer_sk
            AND wp2.wp_type = 'home'))                AS distinct_home_pages
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = ss.ss_ticket_number
    AND cr.cr_item_sk = ss.ss_item_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inv_agg ia ON ia.inv_item_sk = i.i_item_sk
    AND ia.inv_date_sk = d.d_date_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
  AND i.i_current_price BETWEEN 50 AND 200
  AND ca.ca_state = 'CA'
  AND ws.web_name = 'Example Site'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '501-1000'
GROUP BY ROLLUP (d.d_year, s.s_store_name, i.i_category, i.i_brand)
ORDER BY d.d_year, s.s_store_name, i.i_category
LIMIT 100
