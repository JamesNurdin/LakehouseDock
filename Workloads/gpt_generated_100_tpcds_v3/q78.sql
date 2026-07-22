WITH cs_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        SUM(cs.cs_quantity) AS sum_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_ship_mode_sk
),
main_data AS (
    SELECT
        s.s_store_name,
        sm1.sm_type AS cs_ship_mode_type,
        sm3.sm_type AS cr_ship_mode_type,
        SUM(cs_item.cs_net_paid) AS total_cs_net_paid,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(sr.sr_net_loss) AS total_sr_net_loss,
        SUM(cs_item.cs_quantity) AS total_quantity_sold,
        SUM(cr.cr_return_quantity) AS total_quantity_returned
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca_sr_addr ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_refunded_addr_sk = ca_sr_addr.ca_address_sk
    JOIN catalog_sales cs_item ON cr.cr_item_sk = cs_item.cs_item_sk
    JOIN catalog_sales cs_order ON cr.cr_order_number = cs_order.cs_order_number
    JOIN ship_mode sm1 ON cs_item.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN ship_mode sm2 ON cs_order.cs_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN ship_mode sm3 ON cr.cr_ship_mode_sk = sm3.sm_ship_mode_sk
    JOIN customer_address ca_bill ON cs_item.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs_item.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_net_loss > 5000
    )
    GROUP BY
        s.s_store_name,
        sm1.sm_type,
        sm3.sm_type
)
SELECT
    md.s_store_name,
    md.cs_ship_mode_type,
    md.cr_ship_mode_type,
    md.total_cs_net_paid,
    md.total_cr_net_loss,
    md.total_sr_net_loss,
    md.total_quantity_sold,
    md.total_quantity_returned,
    ROW_NUMBER() OVER (ORDER BY md.total_cr_net_loss DESC) AS net_loss_rank
FROM main_data md
UNION ALL
SELECT
    CAST(NULL AS varchar) AS s_store_name,
    sm.sm_type AS cs_ship_mode_type,
    CAST(NULL AS varchar) AS cr_ship_mode_type,
    ca.sum_net_paid AS total_cs_net_paid,
    CAST(NULL AS decimal(7,2)) AS total_cr_net_loss,
    CAST(NULL AS decimal(7,2)) AS total_sr_net_loss,
    ca.sum_quantity AS total_quantity_sold,
    CAST(NULL AS bigint) AS total_quantity_returned,
    CAST(NULL AS bigint) AS net_loss_rank
FROM cs_agg ca
JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY total_cr_net_loss DESC NULLS LAST, s_store_name
