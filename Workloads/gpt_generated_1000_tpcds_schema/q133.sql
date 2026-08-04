WITH ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (5)
        WHERE ws_sold_date_sk BETWEEN 2450815 AND 2450900
    ),
    ss AS (
        SELECT *
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2450815 AND 2450900
    ),
    inv AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               inv_quantity_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand BETWEEN 500 AND 1000
    )

-- Star query based on web_sales
SELECT
    'web' AS source,
    ws.ws_sold_date_sk,
    i.i_item_id,
    i.i_category,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ws.ws_quantity,
    ws.ws_net_paid,
    inv.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
FROM ws_sample ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN inv ON inv.inv_item_sk = ws.ws_item_sk AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
WHERE ws.ws_quantity > 1
  AND i.i_category = 'sports-apparel'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'F'
  AND hd.hd_buy_potential = '1000-5000'

UNION ALL

-- Star query based on store_sales
SELECT
    'store' AS source,
    ss.ss_sold_date_sk,
    i.i_item_id,
    i.i_category,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ss.ss_quantity,
    ss.ss_net_paid,
    inv.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY ss.ss_net_paid DESC) AS sales_rank
FROM ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN inv ON inv.inv_item_sk = ss.ss_item_sk
WHERE ss.ss_quantity > 2
  AND i.i_category = 'decor'
  AND ca.ca_state = 'TX'
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '5000-10000'

EXCEPT

SELECT
    source,
    ws_sold_date_sk,
    i_item_id,
    i_category,
    c_first_name,
    c_last_name,
    ca_city,
    ws_quantity,
    ws_net_paid,
    inv_quantity_on_hand,
    sales_rank
FROM (
    SELECT
        'catalog' AS source,
        cs.cs_sold_date_sk AS ws_sold_date_sk,
        i.i_item_id,
        i.i_category,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cs.cs_quantity AS ws_quantity,
        cs.cs_net_paid AS ws_net_paid,
        inv.inv_quantity_on_hand,
        ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
    WHERE cs.cs_quantity > 3
) t

ORDER BY source,
         ws_sold_date_sk DESC,
         sales_rank
LIMIT 200
