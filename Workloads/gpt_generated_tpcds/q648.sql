WITH sales_agg AS (
    SELECT
        i.i_category      AS i_category,
        d.d_year          AS d_year,
        d.d_month_seq     AS d_month_seq,
        SUM(cs.cs_net_paid)   AS total_sales,
        SUM(cs.cs_quantity)   AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        i.i_category          AS i_category,
        d.d_year              AS d_year,
        d.d_month_seq         AS d_month_seq,
        SUM(cr.cr_net_loss)   AS total_returns_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk      = cs.cs_item_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    s.i_category,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    COALESCE(r.total_returns_loss, 0)               AS total_returns_loss,
    (s.total_sales - COALESCE(r.total_returns_loss, 0)) AS net_profit,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0)            AS total_return_quantity,
    CASE WHEN s.total_quantity = 0 THEN 0
         ELSE COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity
    END                                            AS return_rate
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category   = r.i_category
   AND s.d_year       = r.d_year
   AND s.d_month_seq  = r.d_month_seq
WHERE s.d_year = 2000
ORDER BY s.i_category, s.d_year, s.d_month_seq
