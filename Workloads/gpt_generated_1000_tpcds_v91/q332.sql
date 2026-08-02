WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
),
returns_agg AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damage%'
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_item_sk
),
customer_item_profit AS (
    SELECT
        s.customer_sk,
        s.item_sk,
        s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.customer_sk = r.customer_sk
        AND s.item_sk = r.item_sk
)
SELECT
    DISTINCT
    c.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    regexp_extract(i.i_product_name, '(?i)(Pro|Ultra)', 1) AS product_tag,
    substring(i.i_product_name, 1, 10) AS product_name_prefix,
    CONCAT(c.c_customer_id, '-', i.i_item_id) AS cust_item_key,
    ci.net_profit,
    inv.total_inventory,
    ROW_NUMBER() OVER (ORDER BY ci.net_profit DESC) AS profit_rank,
    (SELECT AVG(cs.cs_net_profit)
     FROM catalog_sales cs
     WHERE cs.cs_item_sk = i.i_item_sk) AS avg_item_profit
FROM customer_item_profit ci
JOIN customer c ON ci.customer_sk = c.c_customer_sk
JOIN item i ON ci.item_sk = i.i_item_sk
CROSS JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
) inv
WHERE regexp_like(i.i_product_name, '(?i)\\b(Pro|Ultra)\\b')
  AND i.i_product_name LIKE '%Series%'
  AND EXISTS (
      SELECT 1
      FROM inventory inv2
      WHERE inv2.inv_item_sk = i.i_item_sk
        AND inv2.inv_quantity_on_hand > 0
  )
ORDER BY ci.net_profit DESC
OFFSET 0
LIMIT 100
