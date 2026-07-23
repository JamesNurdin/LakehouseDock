WITH sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        'catalog' AS channel
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    UNION ALL
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
), agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_item_sk,
        d.d_date AS sale_date,
        s.sold_date_sk AS sale_date_sk,
        s.channel,
        SUM(s.net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count,
        AVG(s.quantity) AS avg_quantity,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_email_address,
        c.c_customer_sk
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)eco')
      AND i.i_product_name LIKE '%Chair%'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_item_sk,
        d.d_date,
        s.sold_date_sk,
        s.channel,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_customer_sk
    HAVING EXISTS (
        SELECT 1
        FROM inventory inv_sub
        WHERE inv_sub.inv_item_sk = i.i_item_sk
          AND inv_sub.inv_date_sk = s.sold_date_sk
          AND inv_sub.inv_quantity_on_hand > 100
    )
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.customer_name,
    regexp_extract(a.c_email_address, '^([^@]+)') AS email_user,
    a.sale_date,
    a.channel,
    a.total_net_profit,
    a.transaction_count,
    a.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY a.i_item_id ORDER BY a.total_net_profit DESC) AS item_rank,
    (SELECT AVG(cs.cs_net_profit) FROM catalog_sales cs WHERE cs.cs_item_sk = a.i_item_sk) AS avg_catalog_profit,
    (SELECT COUNT(*) FROM inventory inv WHERE inv.inv_item_sk = a.i_item_sk AND inv.inv_date_sk = a.sale_date_sk AND inv.inv_quantity_on_hand > 0) AS inventory_on_hand
FROM agg a
ORDER BY a.total_net_profit DESC
LIMIT 100
