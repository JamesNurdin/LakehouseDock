WITH sales_filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ca.ca_state,
        ca.ca_suite_number,
        ca.ca_street_name
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND cd.cd_purchase_estimate >= 5000
      AND ca.ca_state = 'CA'
      AND ca.ca_suite_number NOT LIKE 'Suite 0%'
      AND ca.ca_street_name LIKE 'College%'
)
SELECT
    w.w_warehouse_name,
    ca_ref.ca_state AS customer_state,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(sf.ss_ext_sales_price) AS total_sales_price,
    SUM(sf.ss_ext_sales_price) + SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) AS overall_amount,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS catalog_loss_rank,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(sf.ss_ext_sales_price) DESC) AS sales_row_num,
    (
        SELECT AVG(cd2.cd_purchase_estimate)
        FROM customer_demographics cd2
        WHERE cd2.cd_credit_rating = cd_ref.cd_credit_rating
    ) AS avg_estimate_by_rating
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = (
        SELECT ss_inner.ss_ticket_number
        FROM store_sales ss_inner
        WHERE ss_inner.ss_item_sk = sr.sr_item_sk
          AND ss_inner.ss_ticket_number = sr.sr_ticket_number
        LIMIT 1
    )
JOIN store_sales sf
    ON sr.sr_item_sk = sf.ss_item_sk
   AND sr.sr_ticket_number = sf.ss_ticket_number
JOIN sales_filtered sfilt
    ON sf.ss_ticket_number = sfilt.ss_ticket_number
WHERE w.w_state = 'CA'
  AND cr.cr_return_quantity > 0
  AND sr.sr_return_tax > 10
  AND cr.cr_reason_sk IN (33, 62, 43)
  AND ca_ref.ca_city = 'San Francisco'
GROUP BY w.w_warehouse_name, ca_ref.ca_state, cd_ref.cd_credit_rating
HAVING SUM(sf.ss_ext_sales_price) > 10000
ORDER BY overall_amount DESC
LIMIT 100
