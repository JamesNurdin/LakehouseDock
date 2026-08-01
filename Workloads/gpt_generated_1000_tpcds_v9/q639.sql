WITH base AS (
    SELECT
        wr.wr_order_number AS order_number,
        d_ret.d_date AS return_date,
        d_ret.d_year AS return_year,
        wr.wr_net_loss AS net_loss,
        ca_refund.ca_city AS refund_city,
        ca_refund.ca_state AS refund_state,
        ca_return.ca_city AS return_city,
        ca_return.ca_state AS return_state,
        s.s_store_name AS store_name,
        s.s_state AS store_state,
        s.s_county AS store_county,
        cp.cp_catalog_page_id AS catalog_page_id,
        cp.cp_department AS department,
        cp.cp_catalog_page_number AS catalog_page_number,
        ws.web_name AS web_name,
        ws.web_state AS web_state,
        ws.web_country AS web_country
    FROM web_returns wr
    INNER JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    INNER JOIN customer_address ca_refund
        ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
    INNER JOIN customer_address ca_return
        ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
        AND s.s_county = 'Levy County'
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND wr.wr_net_loss > 0
      AND ws.web_country = 'United States'
      AND NOT EXISTS (
          SELECT 1 FROM customer_address ca_black
          WHERE ca_black.ca_address_sk = ca_return.ca_address_sk
            AND ca_black.ca_state = 'NV'
      )
)
SELECT
    order_number,
    return_date,
    store_name,
    store_state,
    store_county,
    refund_city,
    return_city,
    catalog_page_id,
    department,
    catalog_page_number,
    web_name,
    web_state,
    web_country,
    net_loss,
    CASE
        WHEN net_loss > 1000 THEN 'High'
        WHEN net_loss > 0 THEN 'Low'
        ELSE 'None'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY store_state ORDER BY net_loss DESC) AS loss_rank_state
FROM base
ORDER BY net_loss DESC
LIMIT 100
