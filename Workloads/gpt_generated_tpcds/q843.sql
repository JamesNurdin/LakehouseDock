WITH sales_agg AS (
    SELECT
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales_amount,
        SUM(cs_quantity) AS total_units_sold,
        SUM(cs_ext_discount_amt) AS total_discount_given,
        SUM(cs_ext_tax) AS total_tax_collected,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_warehouse_sk
),
returns_agg AS (
    SELECT
        cr_warehouse_sk,
        SUM(cr_return_quantity) AS total_units_returned,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_return_loss
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank,
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_state,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(s.total_units_sold, 0) AS total_units_sold,
    COALESCE(s.total_discount_given, 0) AS total_discount_given,
    COALESCE(s.total_tax_collected, 0) AS total_tax_collected,
    COALESCE(r.total_units_returned, 0) AS total_units_returned,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    CASE
        WHEN COALESCE(s.total_sales_amount, 0) = 0 THEN 0
        ELSE COALESCE(r.total_return_amount, 0) / CAST(COALESCE(s.total_sales_amount, 0) AS DOUBLE)
    END AS return_amount_ratio,
    CASE
        WHEN COALESCE(s.total_units_sold, 0) = 0 THEN 0
        ELSE COALESCE(r.total_units_returned, 0) / CAST(COALESCE(s.total_units_sold, 0) AS DOUBLE)
    END AS return_units_ratio
FROM warehouse w
LEFT JOIN sales_agg s ON w.w_warehouse_sk = s.cs_warehouse_sk
LEFT JOIN returns_agg r ON w.w_warehouse_sk = r.cr_warehouse_sk
ORDER BY net_profit_after_returns DESC
LIMIT 10
