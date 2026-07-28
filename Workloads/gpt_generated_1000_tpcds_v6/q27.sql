WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        AVG(ws.ws_ext_tax) AS avg_tax,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE i.i_current_price BETWEEN 10 AND 1000                               -- predicate 1
      AND sm.sm_carrier = 'CarrierX'                                           -- predicate 2
      AND wsite.web_mkt_desc LIKE '%thoughts%'                                 -- predicate 3
      AND ca.ca_state = 'CA'                                                   -- predicate 4
      AND cd_bill.cd_dep_employed_count >= 2                                   -- predicate 5
      AND cd_ship.cd_dep_college_count <= 1                                    -- predicate 6
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk, ws.ws_item_sk
),
max_qty_per_item AS (
    SELECT ws_item_sk, MAX(total_qty) AS max_qty
    FROM sales_agg
    GROUP BY ws_item_sk
),
union_sites AS (
    SELECT web_site_sk, web_name
    FROM web_site
    WHERE web_state = 'CA'
    UNION ALL
    SELECT web_site_sk, web_name
    FROM web_site
    WHERE web_state = 'NY'
)
SELECT
    u.web_name,
    AVG(s.total_sales) AS avg_sales_per_item,
    COUNT(DISTINCT s.ws_item_sk) AS distinct_items,
    (SELECT MAX(total_sales) FROM sales_agg) AS overall_max_sales
FROM sales_agg s
JOIN union_sites u
    ON s.ws_web_site_sk = u.web_site_sk
JOIN max_qty_per_item mq
    ON s.ws_item_sk = mq.ws_item_sk
WHERE s.total_qty > mq.max_qty * 0.5
GROUP BY u.web_name
HAVING AVG(s.total_sales) > 5000
ORDER BY avg_sales_per_item DESC
LIMIT 10
