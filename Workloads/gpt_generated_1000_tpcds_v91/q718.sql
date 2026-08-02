WITH customer_sales_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(sr.sr_net_loss) AS total_store_returns,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        AVG(ws.ws_ext_list_price) AS avg_ext_list_price
    FROM customer c
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_list_price > 1000
      AND ws.ws_coupon_amt < 500
      AND sr.sr_return_amt > 0
      AND sr.sr_return_tax BETWEEN 1 AND 20
      AND w.web_city IN ('Mount Olive', 'Lakeview', 'Pine Grove')
      AND w.web_rec_start_date >= DATE '2001-01-01'
      AND w.web_rec_end_date <= DATE '2003-12-31'
      AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
              AND sr2.sr_return_amt > 50
          )
    GROUP BY c.c_customer_sk, c.c_customer_id
),
avg_web_sales AS (
    SELECT AVG(total_web_sales) AS avg_total_web_sales
    FROM customer_sales_returns
),
unioned AS (
    SELECT
        csr.c_customer_sk,
        csr.c_customer_id,
        csr.total_web_sales,
        csr.total_store_returns,
        (csr.total_web_sales + csr.total_store_returns) AS total_combined,
        csr.distinct_orders,
        csr.avg_ext_list_price,
        CASE
            WHEN csr.total_web_sales > (SELECT avg_total_web_sales FROM avg_web_sales)
            THEN 'AboveAvg'
            ELSE 'BelowAvg'
        END AS sales_perf,
        'WebHigher' AS sales_vs_returns_flag
    FROM customer_sales_returns csr
    WHERE csr.total_web_sales > csr.total_store_returns

    UNION

    SELECT
        csr.c_customer_sk,
        csr.c_customer_id,
        csr.total_web_sales,
        csr.total_store_returns,
        (csr.total_web_sales + csr.total_store_returns) AS total_combined,
        csr.distinct_orders,
        csr.avg_ext_list_price,
        CASE
            WHEN csr.total_web_sales > (SELECT avg_total_web_sales FROM avg_web_sales)
            THEN 'AboveAvg'
            ELSE 'BelowAvg'
        END AS sales_perf,
        'ReturnHigher' AS sales_vs_returns_flag
    FROM customer_sales_returns csr
    WHERE csr.total_store_returns >= csr.total_web_sales
)
SELECT
    u.c_customer_sk,
    u.c_customer_id,
    u.total_web_sales,
    u.total_store_returns,
    u.total_combined,
    u.distinct_orders,
    u.avg_ext_list_price,
    u.sales_perf,
    u.sales_vs_returns_flag,
    RANK() OVER (ORDER BY u.total_combined DESC) AS revenue_rank,
    SUM(u.total_combined) OVER (PARTITION BY u.sales_vs_returns_flag) AS sum_combined_by_flag
FROM unioned u
ORDER BY revenue_rank
LIMIT 100
