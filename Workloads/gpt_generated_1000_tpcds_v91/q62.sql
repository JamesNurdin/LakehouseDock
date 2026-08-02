WITH address_facts AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_country,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS ss_total_paid,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS sr_total_return,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS cs_total_paid,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS cr_total_return,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS ws_total_paid
    FROM customer_address ca
    LEFT JOIN store_sales ss
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_state, ca.ca_country
),
intersected_addresses AS (
    SELECT DISTINCT ca1.ca_address_sk
    FROM store_sales ss1
    JOIN customer_address ca1
        ON ss1.ss_addr_sk = ca1.ca_address_sk
    INTERSECT
    SELECT DISTINCT ca2.ca_address_sk
    FROM catalog_sales cs1
    JOIN customer_address ca2
        ON cs1.cs_bill_addr_sk = ca2.ca_address_sk
)
SELECT
    af.ca_address_sk,
    af.ca_state,
    af.ca_country,
    af.ss_total_paid,
    af.sr_total_return,
    af.cs_total_paid,
    af.cr_total_return,
    af.ws_total_paid,
    (af.ss_total_paid + af.cs_total_paid + af.ws_total_paid - af.sr_total_return - af.cr_total_return) AS net_total,
    CASE
        WHEN (af.ss_total_paid + af.cs_total_paid + af.ws_total_paid - af.sr_total_return - af.cr_total_return) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY af.ca_state ORDER BY (af.ss_total_paid + af.cs_total_paid + af.ws_total_paid) DESC) AS state_rank,
    (SELECT COUNT(*)
     FROM store_returns sr_corr
     WHERE sr_corr.sr_addr_sk = af.ca_address_sk
       AND sr_corr.sr_return_amt > 100) AS high_return_count,
    top_items.top_item_sk,
    top_items.top_item_sales,
    sr2.sr_fee,
    cr2.cr_fee,
    ws2.ws_coupon_amt,
    cs2.cs_net_profit
FROM address_facts af
INNER JOIN intersected_addresses ia
    ON af.ca_address_sk = ia.ca_address_sk
LEFT JOIN store_returns sr2
    ON sr2.sr_addr_sk = af.ca_address_sk
LEFT JOIN catalog_returns cr2
    ON cr2.cr_returning_addr_sk = af.ca_address_sk
LEFT JOIN web_sales ws2
    ON ws2.ws_ship_addr_sk = af.ca_address_sk
LEFT JOIN store_sales ss2
    ON ss2.ss_ticket_number = sr2.sr_ticket_number
LEFT JOIN catalog_sales cs2
    ON cs2.cs_order_number = cr2.cr_order_number
LEFT JOIN customer_address ca_ship
    ON cs2.cs_ship_addr_sk = ca_ship.ca_address_sk
CROSS JOIN LATERAL (
    SELECT ss_item_sk AS top_item_sk,
           ss_ext_sales_price AS top_item_sales
    FROM store_sales ss
    WHERE ss.ss_addr_sk = af.ca_address_sk
    ORDER BY ss_ext_sales_price DESC
    LIMIT 1
) AS top_items
WHERE af.ca_address_sk NOT IN (
    SELECT ca_un.ca_address_sk
    FROM customer_address ca_un
    WHERE ca_un.ca_country = 'Canada'
)
ORDER BY net_total DESC
LIMIT 100
