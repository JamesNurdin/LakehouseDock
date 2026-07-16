WITH sales_agg AS (
    SELECT
        ss_item_sk AS item_sk,
        ss_sold_date_sk AS date_sk,
        SUM(ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss_ticket_number) AS sales_txns,
        AVG(ss_ext_discount_amt) AS avg_discount_amt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450900 AND 2451200
      AND ss_quantity > 0
    GROUP BY ss_item_sk, ss_sold_date_sk
),
returns_agg AS (
    SELECT
        cr_item_sk AS item_sk,
        cr_returned_date_sk AS date_sk,
        SUM(cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr_order_number) AS return_txns,
        AVG(cr_return_quantity) AS avg_return_qty
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451200
      AND cr_return_quantity > 10
    GROUP BY cr_item_sk, cr_returned_date_sk
)
SELECT
    s.item_sk,
    s.date_sk,
    s.total_sales_profit,
    r.total_return_loss,
    s.total_sales_profit - r.total_return_loss AS net_gain,
    s.sales_txns,
    r.return_txns,
    s.avg_discount_amt,
    r.avg_return_qty
FROM sales_agg s
JOIN returns_agg r
  ON s.item_sk = r.item_sk
 AND s.date_sk = r.date_sk
WHERE (s.total_sales_profit - r.total_return_loss) > 0
ORDER BY net_gain DESC
LIMIT 10
