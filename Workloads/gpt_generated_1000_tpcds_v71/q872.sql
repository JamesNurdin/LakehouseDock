WITH base_agg AS (
    SELECT
        d.d_year AS year,
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        c.c_customer_id AS customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_ext_sales_price ELSE 0 END) AS high_qty_sales,
        COUNT(cr.cr_return_quantity) AS catalog_return_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory i ON d.d_date_sk = i.inv_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'TX'
      AND s.s_state = 'TX'
      AND we.web_country = 'United States'
      AND ib.ib_upper_bound >= 50000
      AND cr.cr_return_quantity > 0
      AND ss.ss_ext_sales_price > 1000
      AND EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_quantity > 5
      )
    GROUP BY d.d_year, s.s_store_sk, s.s_store_name, c.c_customer_id
)
SELECT DISTINCT
    b.year,
    b.store_name,
    b.total_store_sales,
    b.total_store_profit,
    b.distinct_tickets,
    b.high_qty_sales,
    (SELECT AVG(total_store_sales) FROM base_agg b2 WHERE b2.year = b.year) AS avg_sales_per_year,
    (SELECT COUNT(DISTINCT wp3.wp_web_page_sk)
         FROM web_page wp3
         WHERE wp3.wp_customer_sk = c.c_customer_sk) AS distinct_pages_for_customer
FROM base_agg b
JOIN customer c ON b.customer_id = c.c_customer_id
WHERE b.total_store_sales > (
          SELECT AVG(total_store_sales) FROM base_agg WHERE year = b.year
      )
ORDER BY b.total_store_sales DESC
LIMIT 100
