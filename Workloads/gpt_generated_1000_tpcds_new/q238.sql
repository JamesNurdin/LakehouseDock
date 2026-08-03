WITH intersect_items AS (
    SELECT i.i_item_sk
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    INTERSECT
    SELECT ss.ss_item_sk
    FROM store_sales ss
),
full_store_sales AS (
    SELECT
        s.s_state,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_customer_sk,
        ss.ss_item_sk
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    WHERE s.s_state IS NOT NULL OR ss.ss_net_paid IS NOT NULL
)
SELECT
    state,
    gender,
    SUM(net_paid) AS total_net_paid,
    SUM(quantity) AS total_quantity,
    COUNT(*) AS transaction_cnt
FROM (
    SELECT
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        0.0 AS net_paid,
        0 AS quantity
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 6000

    UNION

    SELECT
        fss.s_state AS state,
        cd.cd_gender AS gender,
        fss.ss_net_paid AS net_paid,
        fss.ss_quantity AS quantity
    FROM full_store_sales fss
    LEFT JOIN customer c ON fss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN intersect_items ii ON fss.ss_item_sk = ii.i_item_sk
    WHERE fss.s_state IS NOT NULL
) AS combined
GROUP BY GROUPING SETS ((state), (state, gender), ())
ORDER BY total_net_paid DESC
LIMIT 100
