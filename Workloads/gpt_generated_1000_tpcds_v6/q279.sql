/* Goal: Analyze combined sales and return performance by state and year, focusing on 2002 Texas stores with vehicle-owning households, and compute cumulative sales per state. */
WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_paid) AS store_net_paid,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'TX'
      AND hd.hd_vehicle_count >= 2
      AND s.s_store_name LIKE '%Super%'
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    s.s_state,
    d.d_year,
    SUM(sa.store_sales_amount) AS total_sales_amount,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    -- cumulative sales for the state ordered by year
    SUM(SUM(sa.store_sales_amount)) OVER (
        PARTITION BY s.s_state
        ORDER BY d.d_year
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_sales_by_state
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
                     AND ss.ss_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE cp.cp_type = 'promo'
  AND wp.wp_type = 'content'
  AND cr.cr_return_quantity > 0
  AND wr.wr_return_quantity > 0
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = cr.cr_refunded_hdemo_sk
          AND hd2.hd_income_band_sk = 5
    )
GROUP BY s.s_state, d.d_year
ORDER BY total_sales_amount DESC
LIMIT 100
