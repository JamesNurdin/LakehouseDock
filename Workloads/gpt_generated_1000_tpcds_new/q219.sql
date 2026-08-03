WITH customers_without_returns AS (
        SELECT ss.ss_customer_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY ss.ss_customer_sk
        EXCEPT
        SELECT sr.sr_customer_sk
        FROM store_returns sr
        JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ),
    max_avg_paid AS (
        SELECT AVG(ss_net_paid) AS avg_paid
        FROM store_sales
        WHERE ss_sold_date_sk = (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2001
        )
    )
SELECT
    d.d_year,
    ca.ca_state,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    d.d_year = 2001
    AND t.t_hour BETWEEN 9 AND 17
    AND ca.ca_country = 'United States'
    AND p.p_discount_active = 'Y'
    AND ib.ib_upper_bound <= 90000
    AND ss.ss_quantity > 1
    AND ss.ss_net_paid > (SELECT avg_paid FROM max_avg_paid)
    AND ss.ss_customer_sk IN (SELECT ss_customer_sk FROM customers_without_returns)
GROUP BY
    d.d_year,
    ca.ca_state,
    p.p_promo_name
ORDER BY
    total_net_paid DESC
LIMIT 100
