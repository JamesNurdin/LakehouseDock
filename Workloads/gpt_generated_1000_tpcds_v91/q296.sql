WITH intersect_customers AS (
    SELECT cs.cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_bill_customer_sk
    INTERSECT
    SELECT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_product_name,
    cs.cs_net_profit + ws.ws_net_profit AS total_net_profit,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY (cs.cs_net_profit + ws.ws_net_profit) DESC) AS profit_rank_state,
    CASE
        WHEN cs.cs_quantity > ws.ws_quantity THEN 'Catalog Faster'
        ELSE 'Web Faster'
    END AS faster_channel,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
    ) AS avg_item_net_profit,
    ws_lateral.max_ws_net_paid
FROM intersect_customers ic
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = ic.c_customer_sk
JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
   AND wp.wp_customer_sk = c.c_customer_sk
CROSS JOIN LATERAL (
    SELECT MAX(ws2.ws_net_paid) AS max_ws_net_paid
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
      AND ws2.ws_item_sk = i.i_item_sk
) AS ws_lateral
CROSS JOIN LATERAL (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           cc.cc_state
    FROM call_center cc
    WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
) AS cc
WHERE
    cc.cc_state = 'CA'
    AND cp.cp_type = 'monthly'
    AND cp.cp_end_date_sk > 2451000
    AND i.i_current_price > 100
    AND c.c_birth_year BETWEEN 1970 AND 1990
    AND cs.cs_quantity > 0
    AND ws.ws_quantity > 0
    AND ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
    AND cr.cr_return_quantity > 0
    AND wp.wp_type = 'content'
ORDER BY total_net_profit DESC
LIMIT 100
