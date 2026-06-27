WITH sales_agg AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        item.i_category,
        promotion.p_promo_name,
        SUM(catalog_sales.cs_net_profit) AS total_sales_profit,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    WHERE date_dim.d_year = 2020
    GROUP BY date_dim.d_year, date_dim.d_month_seq, item.i_category, promotion.p_promo_name
),
returns_agg AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        item.i_category,
        promotion.p_promo_name,
        SUM(catalog_returns.cr_return_amount) AS total_return_amount,
        SUM(catalog_returns.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    JOIN catalog_sales ON catalog_returns.cr_order_number = catalog_sales.cs_order_number
        AND catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
    JOIN date_dim ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
    JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    WHERE date_dim.d_year = 2020
    GROUP BY date_dim.d_year, date_dim.d_month_seq, item.i_category, promotion.p_promo_name
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.p_promo_name,
    s.total_sales_profit,
    r.total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_sales_amount,
    r.total_return_amount,
    s.sales_cnt,
    r.return_cnt,
    CASE WHEN s.total_sales_amount = 0 THEN NULL
         ELSE (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) / s.total_sales_amount END AS profit_margin,
    SUM(s.total_sales_profit - COALESCE(r.total_return_loss, 0)) OVER (
        PARTITION BY s.i_category, s.p_promo_name
        ORDER BY s.d_year, s.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
    AND s.p_promo_name = r.p_promo_name
ORDER BY s.d_year, s.d_month_seq, s.i_category, s.p_promo_name
