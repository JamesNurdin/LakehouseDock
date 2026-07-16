WITH sales_agg AS (
    SELECT
        cs_item_sk,
        SUM(cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs_quantity) AS total_sold_quantity,
        SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_sold_date_sk = 2450815
    GROUP BY cs_item_sk
),
returns_agg AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    WHERE cr_return_quantity > 5
      AND cr_returned_date_sk = 2450815
    GROUP BY cr_item_sk, cr_reason_sk
),
category_return_stats AS (
    SELECT
        i.i_category AS category,
        COALESCE(rs.r_reason_desc, 'No Return') AS reason,
        SUM(s.total_sales_amount) AS total_sales_amount,
        SUM(s.total_sold_quantity) AS total_sold_quantity,
        SUM(COALESCE(r.total_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(r.total_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(r.total_net_loss, 0)) AS total_net_loss,
        SUM(s.total_net_profit) AS total_net_profit,
        SUM(COALESCE(r.total_return_quantity, 0)) / NULLIF(SUM(s.total_sold_quantity), 0) AS return_rate,
        SUM(s.total_net_profit) / NULLIF(SUM(s.total_sold_quantity), 0) AS avg_net_profit_per_sale,
        (SUM(s.total_net_profit) - SUM(COALESCE(r.total_net_loss, 0))) AS profit_after_returns
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.cs_item_sk = r.cr_item_sk
    JOIN item i
        ON s.cs_item_sk = i.i_item_sk
    LEFT JOIN reason rs
        ON r.cr_reason_sk = rs.r_reason_sk
    GROUP BY
        i.i_category,
        COALESCE(rs.r_reason_desc, 'No Return')
)
SELECT
    category,
    reason,
    total_sales_amount,
    total_sold_quantity,
    total_return_amount,
    total_return_quantity,
    return_rate,
    avg_net_profit_per_sale,
    total_net_loss,
    profit_after_returns,
    RANK() OVER (ORDER BY profit_after_returns DESC) AS category_rank
FROM category_return_stats
WHERE total_sales_amount > 1000
ORDER BY profit_after_returns DESC
LIMIT 10
