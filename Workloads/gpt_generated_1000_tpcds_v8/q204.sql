WITH filtered_returns AS (
    SELECT cr_returned_date_sk,
           cr_returned_time_sk,
           cr_item_sk,
           cr_refunded_customer_sk,
           cr_refunded_cdemo_sk,
           cr_refunded_hdemo_sk,
           cr_refunded_addr_sk,
           cr_returning_customer_sk,
           cr_returning_cdemo_sk,
           cr_returning_hdemo_sk,
           cr_returning_addr_sk,
           cr_call_center_sk,
           cr_catalog_page_sk,
           cr_ship_mode_sk,
           cr_warehouse_sk,
           cr_reason_sk,
           cr_order_number,
           cr_return_quantity,
           cr_return_amount,
           cr_return_tax,
           cr_return_amt_inc_tax,
           cr_fee,
           cr_return_ship_cost,
           cr_refunded_cash,
           cr_reversed_charge,
           cr_store_credit,
           cr_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 100.00                         -- predicate 1
      AND cr_return_quantity >= 1                             -- predicate 2
      AND cr_store_credit < 5000.00                           -- predicate 3
      AND cr_returned_date_sk BETWEEN 2450000 AND 2453650     -- predicate 4
      AND cr_warehouse_sk IN (                                 -- predicate 5 (IN subquery)
            SELECT w_warehouse_sk
            FROM warehouse
            WHERE w_state = 'CA'
        )
)
SELECT
    ca.ca_city,
    w.w_warehouse_name,
    COUNT(DISTINCT fr.cr_order_number)          AS order_cnt,
    SUM(fr.cr_return_amount)                    AS total_return_amount,
    AVG(fr.cr_return_tax)                       AS avg_return_tax,
    MIN(fr.cr_return_amt_inc_tax)               AS min_return_inc_tax,
    MAX(fr.cr_return_amt_inc_tax)               AS max_return_inc_tax
FROM filtered_returns fr
FULL OUTER JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk                -- full outer join (rule)
LEFT JOIN customer_address ca
    ON fr.cr_refunded_addr_sk = ca.ca_address_sk            -- left join (rule)
WHERE NOT EXISTS (                                            -- anti‑join
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = fr.cr_order_number
          AND cr2.cr_return_amount > 5000.00
      )
  AND EXISTS (                                               -- semi‑join via EXISTS
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_city = 'Maple Grove'
          AND ca2.ca_address_sk = fr.cr_refunded_addr_sk
      )
  AND w.w_city = 'Hopewell'                                 -- predicate 6
GROUP BY ca.ca_city, w.w_warehouse_name
ORDER BY total_return_amount DESC
LIMIT 100
