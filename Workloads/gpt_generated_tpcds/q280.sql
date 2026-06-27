WITH
sales_agg AS (
    SELECT
        cs.cs_item_sk AS cs_item_sk,
        d_sales.d_year AS d_year,
        d_sales.d_moy AS d_moy,
        i.i_category AS i_category,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_promo_sk) AS promo_count
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_sales.d_date >= DATE '2022-01-01'
      AND d_sales.d_date < DATE '2023-01-01'
    GROUP BY cs.cs_item_sk, d_sales.d_year, d_sales.d_moy, i.i_category
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS cr_item_sk,
        d_ret.d_year AS d_year,
        d_ret.d_moy AS d_moy,
        i.i_category AS i_category,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d_ret.d_date >= DATE '2022-01-01'
      AND d_ret.d_date < DATE '2023-01-01'
    GROUP BY cr.cr_item_sk, d_ret.d_year, d_ret.d_moy, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.total_quantity,
    s.total_sales_amount,
    s.total_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.promo_count
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cs_item_sk = r.cr_item_sk
   AND s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.i_category = r.i_category
ORDER BY s.d_year DESC, s.d_moy DESC, s.total_sales_amount DESC
LIMIT 100
