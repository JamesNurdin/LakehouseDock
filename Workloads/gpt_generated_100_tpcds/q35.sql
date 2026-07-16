/*
  Monthly net‑profit and return analysis by item category
  ----------------------------------------------------
  * Sales side (catalog_sales) is aggregated by the sale date (year + month)
    and the item category, summing net profit, quantity, discount and sales amount.
  * Returns side (catalog_returns) is aggregated by the return date (year + month)
    and the same item category, summing net loss, returned quantity and return amount.
  * The two aggregates are joined on year, month and category to show the net
    profit after accounting for returns, plus useful ratios such as average
    discount per item.
*/
WITH sales_agg AS (
    SELECT
        d_sold.d_year  AS year,
        d_sold.d_moy   AS month,
        i.i_category   AS category,
        SUM(cs.cs_net_profit)        AS total_sales_profit,
        SUM(cs.cs_quantity)          AS total_quantity_sold,
        SUM(cs.cs_ext_discount_amt)  AS total_discount_amount,
        SUM(cs.cs_ext_sales_price)   AS total_sales_amount
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d_sold.d_year, d_sold.d_moy, i.i_category
),
returns_agg AS (
    SELECT
        d_ret.d_year  AS year,
        d_ret.d_moy   AS month,
        i.i_category  AS category,
        SUM(cr.cr_net_loss)       AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        SUM(cr.cr_return_amount)   AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d_ret.d_year, d_ret.d_moy, i.i_category
)
SELECT
    s.year,
    s.month,
    s.category,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0)                AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0)          AS total_quantity_returned,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0)              AS total_return_amount,
    CASE
        WHEN s.total_quantity_sold > 0 THEN s.total_discount_amount / s.total_quantity_sold
        ELSE 0
    END                                            AS avg_discount_per_item
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.year = r.year
   AND s.month = r.month
   AND s.category = r.category
ORDER BY s.year, s.month, s.category
