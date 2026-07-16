WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d.d_date_sk AS d_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) FILTER (WHERE ss.ss_coupon_amt > 0) AS num_coupons_used
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_date_sk
),
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS d_date_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(cr.cr_order_number) AS num_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
)
SELECT
    s.s_store_id,
    w.web_site_id,
    d.d_year,
    d.d_month_seq,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.total_profit, 0) AS total_profit,
    COALESCE(sa.num_transactions, 0) AS num_transactions,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    COALESCE(ra.num_returns, 0) AS num_returns,
    CASE
        WHEN COALESCE(sa.total_sales, 0) = 0 THEN NULL
        ELSE COALESCE(ra.total_return_loss, 0) / COALESCE(sa.total_sales, 0)
    END AS return_loss_ratio,
    COALESCE(sa.avg_discount, 0) AS avg_discount,
    COALESCE(sa.num_coupons_used, 0) AS num_coupons_used
FROM date_dim d
JOIN sales_agg sa ON sa.d_date_sk = d.d_date_sk
JOIN returns_agg ra ON ra.d_date_sk = d.d_date_sk
JOIN store s ON s.s_store_sk = sa.ss_store_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND d_closure.d_year >= 2001
  AND s.s_state = 'CA'
ORDER BY total_sales DESC
LIMIT 100
