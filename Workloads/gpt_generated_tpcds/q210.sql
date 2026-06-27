WITH sales AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_moy,
        p.p_promo_name,
        p.p_discount_active,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2022
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_moy,
        p.p_promo_name,
        p.p_discount_active
),
returns AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_moy
)
SELECT
    s.s_store_id,
    s.d_year,
    s.d_moy,
    s.p_promo_name,
    s.p_discount_active,
    s.total_net_paid,
    s.total_net_profit,
    s.total_discount,
    s.distinct_customers,
    s.sales_transactions,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.return_transactions, 0) AS return_transactions,
    CASE WHEN s.sales_transactions > 0 THEN s.total_discount / s.sales_transactions ELSE 0 END AS avg_discount_per_tx
FROM sales s
LEFT JOIN returns r
    ON s.s_store_id = r.s_store_id
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
ORDER BY s.total_net_profit DESC
LIMIT 100
