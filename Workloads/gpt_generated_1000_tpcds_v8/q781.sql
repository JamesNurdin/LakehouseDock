WITH
    sampled_sales AS (
        SELECT cs_order_number, cs_item_sk, cs_net_paid
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_keep AS (
        SELECT cs_order_number, cs_item_sk, cs_net_paid
        FROM sampled_sales
        WHERE cs_order_number IN (
            SELECT cs_order_number
            FROM catalog_sales
            EXCEPT
            SELECT cr_order_number
            FROM catalog_returns
        )
    ),
    sales_per_item AS (
        SELECT cs_item_sk,
               SUM(cs_net_paid) AS total_sales_net
        FROM sales_keep
        GROUP BY cs_item_sk
    ),
    full_returns AS (
        SELECT cr_order_number AS order_number,
               cr_item_sk      AS item_sk,
               cr_return_amount AS return_amount
        FROM catalog_returns
        UNION
        SELECT sr_ticket_number AS order_number,
               sr_item_sk       AS item_sk,
               sr_return_amt    AS return_amount
        FROM store_returns
    ),
    joined_returns AS (
        SELECT fr.item_sk,
               fr.order_number,
               fr.return_amount,
               i.i_product_name,
               i.i_category
        FROM full_returns fr
        FULL OUTER JOIN item i
            ON fr.item_sk = i.i_item_sk
    ),
    return_agg AS (
        SELECT item_sk,
               SUM(return_amount) AS total_return_amount
        FROM joined_returns
        GROUP BY item_sk
    )
SELECT
    spi.cs_item_sk      AS item_sk,
    i.i_product_name,
    i.i_category,
    spi.total_sales_net,
    COALESCE(r.total_return_amount, 0) AS total_return_amount
FROM sales_per_item spi
LEFT JOIN return_agg r
    ON spi.cs_item_sk = r.item_sk
JOIN item i
    ON spi.cs_item_sk = i.i_item_sk
ORDER BY spi.total_sales_net DESC
LIMIT 100
