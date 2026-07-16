WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        d_sales.d_year AS year,
        d_sales.d_moy AS month,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_sales.d_year, d_sales.d_moy
),
catalog_returns_agg AS (
    SELECT
        i.i_category AS category,
        d_cr.d_year AS year,
        d_cr.d_moy AS month,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(cr.cr_net_loss) AS total_cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_cr.d_year, d_cr.d_moy
),
store_returns_agg AS (
    SELECT
        i.i_category AS category,
        d_sr.d_year AS year,
        d_sr.d_moy AS month,
        SUM(sr.sr_return_amt) AS total_sr_return_amount,
        SUM(sr.sr_net_loss) AS total_sr_net_loss
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_sr.d_year, d_sr.d_moy
),
web_returns_agg AS (
    SELECT
        i.i_category AS category,
        d_wr.d_year AS year,
        d_wr.d_moy AS month,
        SUM(wr.wr_return_amt) AS total_wr_return_amount,
        SUM(wr.wr_net_loss) AS total_wr_net_loss
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_wr.d_year, d_wr.d_moy
),
promotion_agg AS (
    SELECT
        i.i_category AS category,
        d_p.d_year AS year,
        d_p.d_moy AS month,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN date_dim d_p ON p.p_start_date_sk = d_p.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_p.d_year, d_p.d_moy
),
inventory_agg AS (
    SELECT
        i.i_category AS category,
        d_inv.d_year AS year,
        d_inv.d_moy AS month,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category, d_inv.d_year, d_inv.d_moy
)
SELECT
    s.category,
    s.year,
    s.month,
    s.total_sales,
    COALESCE(cr.total_cr_return_amount, 0) + COALESCE(sr.total_sr_return_amount, 0) + COALESCE(wr.total_wr_return_amount, 0) AS total_returns_amount,
    s.total_profit,
    COALESCE(cr.total_cr_net_loss, 0) + COALESCE(sr.total_sr_net_loss, 0) + COALESCE(wr.total_wr_net_loss, 0) AS total_returns_net_loss,
    COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
    COALESCE(inv.avg_inventory_on_hand, 0) AS avg_inventory_on_hand,
    s.total_sales - (COALESCE(cr.total_cr_return_amount, 0) + COALESCE(sr.total_sr_return_amount, 0) + COALESCE(wr.total_wr_return_amount, 0)) AS net_sales,
    s.total_profit - (COALESCE(cr.total_cr_net_loss, 0) + COALESCE(sr.total_sr_net_loss, 0) + COALESCE(wr.total_wr_net_loss, 0)) - COALESCE(p.total_promo_cost, 0) AS net_profit_after_promo
FROM sales_agg s
LEFT JOIN catalog_returns_agg cr ON s.category = cr.category AND s.year = cr.year AND s.month = cr.month
LEFT JOIN store_returns_agg sr ON s.category = sr.category AND s.year = sr.year AND s.month = sr.month
LEFT JOIN web_returns_agg wr ON s.category = wr.category AND s.year = wr.year AND s.month = wr.month
LEFT JOIN promotion_agg p ON s.category = p.category AND s.year = p.year AND s.month = p.month
LEFT JOIN inventory_agg inv ON s.category = inv.category AND s.year = inv.year AND s.month = inv.month
ORDER BY s.year, s.month, s.category
