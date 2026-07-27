WITH sales_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_paid AS net_paid,
        COALESCE(sr.sr_return_amt, 0) AS return_amount,
        COALESCE(sr.sr_net_loss, 0) AS net_loss,
        c.c_customer_id,
        ca.ca_country,
        s.s_store_name,
        s.s_state,
        s.s_rec_end_date,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_type,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_country = 'United States'
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND s.s_rec_end_date = DATE '2000-03-12'
)
SELECT
    s.s_store_name,
    s.s_state,
    ca.ca_country,
    ib.ib_lower_bound,
    wp.wp_type,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(sales_amount) AS total_sales,
    SUM(return_amount) AS total_returns,
    SUM(net_paid) AS total_net_paid,
    SUM(net_loss) AS total_net_loss,
    AVG(ib.ib_lower_bound) AS avg_income_lower_bound
FROM sales_returns sr
JOIN store s        ON sr.s_store_name = s.s_store_name AND sr.s_state = s.s_state
JOIN customer c     ON sr.c_customer_id = c.c_customer_id
JOIN customer_address ca ON sr.ca_country = ca.ca_country
JOIN income_band ib  ON sr.ib_lower_bound = ib.ib_lower_bound
JOIN web_page wp    ON sr.wp_type = wp.wp_type
GROUP BY
    s.s_store_name,
    s.s_state,
    ca.ca_country,
    ib.ib_lower_bound,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
