WITH sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_sold_qty,
        SUM(ss_ext_sales_price) AS total_sales_amount,
        SUM(ss_net_profit) AS total_sales_profit,
        AVG(ss_sales_price) AS avg_sales_price,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss_store_sk) AS store_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 24500 AND 25000
      AND ss_ext_discount_amt > 0
    GROUP BY ss_item_sk
),
returns_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_fee) AS avg_return_fee
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 24500 AND 25000
      AND cr_return_ship_cost > 100
      AND cr_fee < 60
    GROUP BY cr_item_sk
)
SELECT
    s.ss_item_sk AS item_sk,
    s.total_sold_qty,
    r.total_return_qty,
    s.total_sales_amount,
    r.total_return_amount,
    (r.total_return_qty / NULLIF(s.total_sold_qty, 0)) AS return_rate,
    (r.total_return_amount / NULLIF(s.total_sales_amount, 0)) AS return_amount_ratio,
    (s.total_sales_profit - r.total_net_loss) AS net_profit_after_returns,
    ROW_NUMBER() OVER (ORDER BY (s.total_sales_profit - r.total_net_loss) DESC) AS profit_rank
FROM sales_agg s
JOIN returns_agg r
    ON s.ss_item_sk = r.cr_item_sk
WHERE s.total_sold_qty > 0
  AND (r.total_return_qty / NULLIF(s.total_sold_qty, 0)) > 0.1
ORDER BY net_profit_after_returns DESC
LIMIT 100
