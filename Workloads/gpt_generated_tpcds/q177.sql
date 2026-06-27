WITH sales_agg AS (
    SELECT
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS sales_transactions
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        p.p_promo_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_name, d_ret.d_year, d_ret.d_month_seq
)
SELECT
    s.p_promo_name,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.distinct_customers,
    s.sales_transactions,
    COALESCE(r.return_transactions, 0) AS return_transactions,
    (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.p_promo_name = r.p_promo_name
   AND s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year, s.d_month_seq, s.total_sales DESC
LIMIT 100
