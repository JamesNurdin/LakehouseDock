WITH sales_agg AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id,
        cd.cd_credit_rating,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_credit_rating
),
returns_agg AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id,
        cd.cd_credit_rating,
        SUM(wr.wr_net_loss) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_return_amt > 1000
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_credit_rating
),
combined AS (
    SELECT
        customer_sk,
        c_customer_id,
        cd_credit_rating,
        total_sales AS amount,
        sales_cnt AS txn_cnt,
        'sale' AS src
    FROM sales_agg
    UNION ALL
    SELECT
        customer_sk,
        c_customer_id,
        cd_credit_rating,
        total_returns AS amount,
        returns_cnt AS txn_cnt,
        'return' AS src
    FROM returns_agg
)
SELECT
    r.customer_sk,
    r.c_customer_id,
    r.cd_credit_rating,
    r.amount,
    r.txn_cnt,
    r.src,
    (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_bill_customer_sk = r.customer_sk) AS total_sales_transactions
FROM combined r
WHERE r.amount > (
    SELECT AVG(c2.amount)
    FROM combined c2
    WHERE c2.src = r.src
)
ORDER BY r.amount DESC
LIMIT 100
