WITH joined AS (
    SELECT
        d.d_year,
        d.d_date_sk,
        ca.ca_state,
        ca.ca_address_sk,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        ss.ss_ticket_number,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        wp.wp_type,
        r.r_reason_desc,
        r.r_reason_sk,
        wr.wr_return_amt
    FROM date_dim d
    FULL OUTER JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND ss.ss_quantity > 5
      AND ws.ws_quantity < 10
)
SELECT
    d_year,
    ca_state,
    SUM(ss_ext_sales_price) AS store_sales_total,
    SUM(ws_ext_sales_price) AS web_sales_total,
    COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws_order_number) AS web_order_cnt,
    AVG(wr_return_amt) AS avg_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ss_ext_sales_price) DESC) AS year_rank
FROM joined j
WHERE EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_reason_sk = j.r_reason_sk
      AND wr2.wr_return_amt > 0
)
GROUP BY GROUPING SETS (
    (d_year, ca_state),
    (d_year),
    (ca_state),
    ()
)
ORDER BY store_sales_total DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
