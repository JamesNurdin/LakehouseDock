WITH sales_union AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        i.i_item_id AS item_id,
        ss.ss_sold_date_sk AS sale_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid > 0
    GROUP BY ss.ss_item_sk, i.i_item_id, ss.ss_sold_date_sk

    UNION

    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_item_id AS item_id,
        cs.cs_sold_date_sk AS sale_date_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_net_paid > 0
    GROUP BY cs.cs_item_sk, i.i_item_id, cs.cs_sold_date_sk
)
SELECT
    item_sk,
    item_id,
    sale_date_sk,
    total_quantity,
    total_net_paid,
    row_number() OVER (PARTITION BY item_id ORDER BY total_net_paid DESC) AS rn
FROM sales_union
ORDER BY total_net_paid DESC
LIMIT 100
