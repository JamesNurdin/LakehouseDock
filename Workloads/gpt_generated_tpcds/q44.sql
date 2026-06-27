WITH sales_by_cust AS (
    SELECT
        cs_bill_customer_sk AS c_customer_sk,
        sum(cs_net_paid) AS total_sales,
        sum(cs_net_profit) AS total_profit,
        count(*) AS sales_txn_cnt
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
returns_by_cust AS (
    SELECT
        sr_customer_sk AS c_customer_sk,
        sum(sr_return_amt) AS total_returns,
        sum(sr_net_loss) AS total_loss,
        count(*) AS return_txn_cnt
    FROM store_returns
    GROUP BY sr_customer_sk
),
pages_by_cust AS (
    SELECT
        wp_customer_sk AS c_customer_sk,
        count(DISTINCT wp_web_page_id) AS distinct_pages,
        sum(wp_char_count) AS total_characters
    FROM web_page
    GROUP BY wp_customer_sk
)
SELECT
    c.c_customer_id,
    s.total_sales,
    r.total_returns,
    p.distinct_pages,
    (s.total_sales - coalesce(r.total_returns, 0)) AS net_revenue,
    s.total_profit,
    (s.total_profit / nullif(s.total_sales, 0)) AS profit_margin,
    s.sales_txn_cnt,
    r.return_txn_cnt,
    p.total_characters
FROM customer c
LEFT JOIN sales_by_cust s
    ON c.c_customer_sk = s.c_customer_sk
LEFT JOIN returns_by_cust r
    ON c.c_customer_sk = r.c_customer_sk
LEFT JOIN pages_by_cust p
    ON c.c_customer_sk = p.c_customer_sk
WHERE s.c_customer_sk IS NOT NULL
ORDER BY net_revenue DESC
LIMIT 100
