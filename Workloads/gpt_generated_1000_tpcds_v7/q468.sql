WITH combined AS (
    SELECT
        ss.ss_sold_date_sk AS date_key,
        ca.ca_state AS state,
        ss.ss_net_profit AS amount,
        'store_sales' AS source_type
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_net_profit > 1000
      AND ca.ca_state IN ('CA', 'TX')
    UNION ALL
    SELECT
        cr.cr_returned_date_sk AS date_key,
        ca.ca_state AS state,
        -cr.cr_net_loss AS amount,
        'catalog_returns' AS source_type
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 500
      AND cp.cp_department = 'Electronics'
      AND ca.ca_state IN ('CA', 'TX')
)
SELECT date_key,
       state,
       amount,
       source_type
FROM combined
ORDER BY date_key DESC,
         amount DESC
LIMIT 100
