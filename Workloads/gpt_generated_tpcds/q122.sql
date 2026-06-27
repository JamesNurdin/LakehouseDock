WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_moy, w.w_warehouse_name
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_moy, w.w_warehouse_name
)
SELECT
    s.d_year,
    s.d_moy,
    s.w_warehouse_name,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.w_warehouse_name = r.w_warehouse_name
ORDER BY s.d_year, s.d_moy, s.w_warehouse_name
