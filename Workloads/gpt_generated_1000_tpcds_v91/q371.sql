WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        w.w_state,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(cs.cs_net_paid) AS avg_cs_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(CASE WHEN cr.cr_return_amount > 1000 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount
    FROM sampled_store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ca.ca_gmt_offset = -7.00
      AND w.w_gmt_offset = -7.00
      AND ca.ca_county = 'Washington County'
      AND ss.ss_quantity > 1
      AND cs.cs_quantity > 1
      AND cr.cr_return_amount > 0
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
    GROUP BY w.w_state, ca.ca_state
    HAVING SUM(ss.ss_net_paid) > 1000
)
SELECT
    w_state,
    ca_state,
    total_net_paid,
    avg_cs_net_paid,
    distinct_tickets,
    high_return_amount,
    ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_net_paid DESC) AS rank_within_state
FROM joined
ORDER BY total_net_paid DESC
LIMIT 100
