WITH high_credit_cdemo AS (
    SELECT DISTINCT cd_demo_sk
    FROM customer_demographics
    WHERE cd_credit_rating = 'Excellent'
),
sales_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        d.d_date_sk AS date_sk,
        d.d_date AS trans_date,
        'sale' AS txn_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND i.i_current_price > 100
      AND cd.cd_demo_sk IN (SELECT cd_demo_sk FROM high_credit_cdemo)
    GROUP BY i.i_item_sk, i.i_item_desc, d.d_date_sk, d.d_date
),
returns_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_desc AS item_desc,
        d.d_date_sk AS date_sk,
        d.d_date AS trans_date,
        'return' AS txn_type,
        SUM(sr.sr_return_amt) AS total_sales,
        SUM(sr.sr_net_loss) AS total_profit
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND sr.sr_refunded_cash > 0
    GROUP BY i.i_item_sk, i.i_item_desc, d.d_date_sk, d.d_date
),
combined AS (
    SELECT
        item_sk,
        item_desc,
        date_sk,
        trans_date,
        txn_type,
        total_sales,
        total_profit
    FROM sales_data
    UNION ALL
    SELECT
        item_sk,
        item_desc,
        date_sk,
        trans_date,
        txn_type,
        total_sales,
        total_profit
    FROM returns_data
),
aggregated AS (
    SELECT
        item_sk,
        item_desc,
        date_sk,
        trans_date,
        SUM(
            CASE WHEN txn_type = 'sale'
                THEN total_sales - total_profit
                ELSE -(total_sales - total_profit)
            END
        ) AS net_amount
    FROM combined
    GROUP BY item_sk, item_desc, date_sk, trans_date
    HAVING SUM(
            CASE WHEN txn_type = 'sale'
                THEN total_sales - total_profit
                ELSE -(total_sales - total_profit)
            END
        ) > 0
)
SELECT
    a.item_sk,
    a.item_desc,
    a.trans_date,
    a.net_amount
FROM aggregated a
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = a.item_sk
      AND inv.inv_date_sk = a.date_sk
)
ORDER BY a.net_amount DESC
LIMIT 100
