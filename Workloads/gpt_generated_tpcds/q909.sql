WITH sales_agg AS (
    SELECT
        cc.cc_name AS cc_name,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_orders
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cc.cc_name AS cc_name,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_orders
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cc.cc_name, d.d_year, d.d_month_seq
),
joined AS (
    SELECT
        s.cc_name,
        s.d_year,
        s.d_month_seq,
        s.total_net_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
        s.total_sales,
        s.sales_orders,
        COALESCE(r.return_orders, 0) AS return_orders
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.cc_name = r.cc_name
        AND s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
)
SELECT
    cc_name,
    d_year,
    d_month_seq,
    total_net_profit,
    total_return_loss,
    net_profit_after_returns,
    total_sales,
    sales_orders,
    return_orders,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM joined
ORDER BY d_year, d_month_seq, profit_rank
