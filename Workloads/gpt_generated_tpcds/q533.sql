WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        cp.cp_catalog_page_id,
        i.i_category,
        SUM(cs.cs_ext_sales_price)      AS total_sales_amount,
        SUM(cs.cs_quantity)             AS total_quantity_sold,
        SUM(cs.cs_ext_discount_amt)     AS total_discount_amount,
        SUM(cs.cs_net_profit)           AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim ds      ON cs.cs_sold_date_sk   = ds.d_date_sk
    JOIN catalog_page cp  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i           ON cs.cs_item_sk        = i.i_item_sk
    WHERE ds.d_year = 2001
    GROUP BY ds.d_year, ds.d_moy, cp.cp_catalog_page_id, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_moy,
        cp.cp_catalog_page_id,
        i.i_category,
        SUM(cr.cr_return_amount)   AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss)        AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim dr      ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN catalog_page cp  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i           ON cr.cr_item_sk        = i.i_item_sk
    WHERE dr.d_year = 2001
    GROUP BY dr.d_year, dr.d_moy, cp.cp_catalog_page_id, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.cp_catalog_page_id,
    s.i_category,
    s.total_sales_amount,
    s.total_quantity_sold,
    s.total_discount_amount,
    s.total_net_profit,
    COALESCE(r.total_return_amount, 0)   AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_loss, 0)     AS total_return_loss,
    CASE WHEN s.total_quantity_sold > 0
         THEN COALESCE(r.total_return_quantity, 0) / s.total_quantity_sold
         ELSE 0
    END                                   AS return_rate,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year               = r.d_year
   AND s.d_moy                = r.d_moy
   AND s.cp_catalog_page_id   = r.cp_catalog_page_id
   AND s.i_category           = r.i_category
ORDER BY s.total_sales_amount DESC
LIMIT 100
