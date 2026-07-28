WITH sr AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_net_loss,
        sr.sr_returned_date_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d_sr.d_year = 2001
      AND s.s_geography_class = 'Unknown'
      AND c.c_preferred_cust_flag = 'Y'
),
wr AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_refunded_addr_sk AS addr_sk,
        wr.wr_web_page_sk
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    WHERE d_wr.d_year = 2001
      AND wp.wp_type = 'Home'
      AND c_refund.c_preferred_cust_flag = 'Y'
),
combined AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_addr_sk AS addr_sk,
        sr.sr_store_sk AS store_sk,
        'store' AS channel
    FROM sr
    UNION ALL
    SELECT
        wr.customer_sk,
        wr.wr_net_loss,
        wr.wr_returned_date_sk,
        wr.addr_sk,
        NULL AS store_sk,
        'web' AS channel
    FROM wr
)
SELECT
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    SUM(comb.net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    RANK() OVER (ORDER BY SUM(comb.net_loss) DESC) AS loss_rank
FROM combined comb
JOIN customer cust ON comb.customer_sk = cust.c_customer_sk
JOIN customer_address ca ON comb.addr_sk = ca.ca_address_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = comb.return_date_sk
JOIN date_dim d_cp ON cp.cp_start_date_sk = d_cp.d_date_sk
WHERE cp.cp_department = 'Electronics'
  AND ca.ca_country = 'United States'
  AND cust.c_birth_year BETWEEN 1970 AND 1990
GROUP BY cust.c_customer_id, cust.c_first_name, cust.c_last_name
ORDER BY total_net_loss DESC
LIMIT 100
