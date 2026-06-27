WITH sales_agg AS (
    SELECT
        d_sales.d_year,
        d_sales.d_month_seq,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    GROUP BY d_sales.d_year, d_sales.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        d_return.d_year,
        d_return.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    GROUP BY d_return.d_year, d_return.d_month_seq, i.i_category
),
inventory_agg AS (
    SELECT
        d_inv.d_year,
        d_inv.d_month_seq,
        i.i_category,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY d_inv.d_year, d_inv.d_month_seq, i.i_category
)
SELECT
    s.d_year AS year,
    s.d_month_seq AS month_seq,
    s.i_category AS category,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    COALESCE(i.avg_inventory_on_hand, 0) AS avg_inventory_on_hand
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
LEFT JOIN inventory_agg i
    ON s.d_year = i.d_year
    AND s.d_month_seq = i.d_month_seq
    AND s.i_category = i.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
