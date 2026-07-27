WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM tpcds.store_sales ss
    WHERE ss.ss_quantity > 1
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ca.ca_city,
    hd.hd_vehicle_count,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(sr.sr_fee) AS avg_return_fee,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
    MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
FROM filtered_sales ss
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   AND cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE
    s.s_state = 'CA'
    AND hd.hd_vehicle_count = 2
    AND hd.hd_dep_count = 1
    AND cr.cr_store_credit > 50
    AND sr.sr_fee > 15
    AND ca.ca_city = 'Los Angeles'
    AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_fee > 20
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    ca.ca_city,
    hd.hd_vehicle_count
HAVING
    SUM(ss.ss_net_paid) > 10000
    AND COUNT(DISTINCT ss.ss_item_sk) > 5
ORDER BY
    total_net_paid DESC
LIMIT 100
