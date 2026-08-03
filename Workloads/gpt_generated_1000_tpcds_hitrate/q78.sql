WITH agg_store_sales AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_net_paid)        AS total_store_net_paid,
        SUM(ss_quantity)        AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_sk, ss_ticket_number
),
order_exceptions AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
)
SELECT
    ROW_NUMBER() OVER (ORDER BY cs.cs_order_number)               AS rn,
    cs.cs_order_number,
    cp.cp_department,
    sm1.sm_type                        AS catalog_ship_type,
    cd_bill.cd_gender                  AS bill_gender,
    cd_ship.cd_gender                  AS ship_gender,
    SUM(agg.total_store_net_paid)      AS total_store_net_paid,
    SUM(ws.ws_net_paid)                AS total_web_net_paid,
    COUNT(*)                           AS txn_count
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk                                 -- rule 7
JOIN ship_mode sm1
    ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk                                     -- rule 8
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk                                     -- rule 5
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk                                     -- rule 6
-- Path to store_sales through store_returns
JOIN store_returns sr
    ON sr.sr_item_sk = cs.cs_item_sk   -- (indirect; the link is via customer demographics below)
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk                                          -- rule 3
JOIN agg_store_sales agg
    ON agg.ss_item_sk = sr.sr_item_sk
   AND agg.ss_ticket_number = sr.sr_ticket_number                                 -- rules 2 & 4
-- Web sales joins
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk                                     -- rule 15
JOIN customer_demographics cd_ws_ship
    ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk                                 -- rule 16
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk                                 -- rule 18
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk                                      -- rule 17
WHERE cs.cs_order_number IN (SELECT cs_order_number FROM order_exceptions)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = cs.cs_item_sk
          AND cr.cr_return_quantity > 0
    )
GROUP BY
    cs.cs_order_number,
    cp.cp_department,
    sm1.sm_type,
    cd_bill.cd_gender,
    cd_ship.cd_gender
ORDER BY cs.cs_order_number
LIMIT 100
