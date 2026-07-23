WITH
    agg_returns AS (
        SELECT
            cr_item_sk AS item_sk,
            cr_refunded_cdemo_sk AS refunded_demo_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_net_loss) AS total_return_net_loss,
            COUNT(*) AS return_cnt
        FROM catalog_returns
        WHERE cr_return_quantity > 0
          AND cr_return_amount > 10
          AND cr_refunded_cdemo_sk IS NOT NULL
          AND cr_item_sk IS NOT NULL
        GROUP BY cr_item_sk, cr_refunded_cdemo_sk
    ),
    agg_sales AS (
        SELECT
            ws_item_sk AS item_sk,
            ws_bill_cdemo_sk AS bill_demo_sk,
            SUM(ws_ext_sales_price) AS total_sales_amount,
            SUM(ws_net_profit) AS total_sales_profit,
            COUNT(*) AS sales_cnt
        FROM web_sales
        WHERE ws_quantity > 0
          AND ws_ext_sales_price > 100
          AND ws_net_profit > 0
          AND ws_bill_cdemo_sk IS NOT NULL
        GROUP BY ws_item_sk, ws_bill_cdemo_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    i.i_wholesale_cost,
    cd_refunded.cd_gender AS refunded_gender,
    cd_bill.cd_gender AS billing_gender,
    agg_returns.total_return_amount,
    agg_returns.total_return_net_loss,
    agg_sales.total_sales_amount,
    agg_sales.total_sales_profit,
    agg_sales.sales_cnt,
    agg_returns.return_cnt,
    (agg_sales.total_sales_amount - agg_returns.total_return_amount) AS net_sales_minus_returns,
    RANK() OVER (ORDER BY (agg_sales.total_sales_profit - agg_returns.total_return_net_loss) DESC) AS profit_rank
FROM agg_returns
JOIN agg_sales
    ON agg_returns.item_sk = agg_sales.item_sk
JOIN item i
    ON agg_returns.item_sk = i.i_item_sk
JOIN customer_demographics cd_refunded
    ON agg_returns.refunded_demo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_bill
    ON agg_sales.bill_demo_sk = cd_bill.cd_demo_sk
WHERE i.i_wholesale_cost BETWEEN 0.5 AND 20
  AND i.i_formulation LIKE '%goldenrod%'
  AND cd_refunded.cd_education_status = 'College'
  AND cd_bill.cd_credit_rating = 'A'
ORDER BY profit_rank
LIMIT 100
