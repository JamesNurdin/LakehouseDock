WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        ws.ws_ext_wholesale_cost,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_ship_tax > 1500.00                     -- high‑value orders
      AND ws.ws_quantity >= 2                                        -- at least 2 items
      AND ws.ws_ext_discount_amt < 100.00                            -- modest discount
      AND ws.ws_ext_wholesale_cost BETWEEN 500.00 AND 6000.00        -- realistic cost range
      AND ws.ws_item_sk IN (
            SELECT ws_inner.ws_item_sk
            FROM web_sales ws_inner
            WHERE ws_inner.ws_quantity > 5
        )                                                          -- only items frequently bought in larger qty
),
address_ca AS (
    SELECT DISTINCT ca_address_sk, ca_state, ca_country
    FROM customer_address
    WHERE ca_country = 'United States'                             -- restrict to US addresses
)
SELECT
    ws.ws_web_site_sk,
    ws_site.web_name,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS avg_paid,
    MIN(ws.ws_net_paid) AS min_paid,
    MAX(ws.ws_net_paid) AS max_paid
FROM filtered_sales ws
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN address_ca ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE ws_site.web_manager = 'John Ward'                               -- manager filter
  AND ws_site.web_mkt_class LIKE '%New%'                               -- market class contains "New"
  AND cd.cd_marital_status = 'M'                                      -- married customers
  AND EXISTS (
        SELECT 1
        FROM customer_address ca_ship
        WHERE ca_ship.ca_state = 'CA'
          AND ca_ship.ca_address_sk = ws.ws_ship_addr_sk
    )                                                                -- shipped to California addresses
GROUP BY
    ws.ws_web_site_sk,
    ws_site.web_name,
    ca.ca_state,
    cd.cd_gender
ORDER BY total_profit DESC
LIMIT 100
