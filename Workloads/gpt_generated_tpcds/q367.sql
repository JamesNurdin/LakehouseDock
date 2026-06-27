WITH sales_agg AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM
        catalog_sales cs
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        p.p_promo_name
),

returns_agg AS (
    SELECT
        d_ret.d_year AS year,
        d_ret.d_month_seq AS month_seq,
        p.p_promo_name AS promo_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM
        catalog_returns cr
        JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        JOIN date_dim d_ret
            ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        p.p_promo_name
),

inventory_agg AS (
    SELECT
        d_inv.d_year AS year,
        d_inv.d_month_seq AS month_seq,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM
        inventory inv
        JOIN date_dim d_inv
            ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY
        d_inv.d_year,
        d_inv.d_month_seq
)

SELECT
    COALESCE(s.year, r.year, i.year) AS year,
    COALESCE(s.month_seq, r.month_seq, i.month_seq) AS month_seq,
    COALESCE(s.promo_name, r.promo_name) AS promo_name,
    s.total_sales_net_paid,
    s.total_sales_net_profit,
    s.total_quantity_sold,
    r.total_return_amount,
    r.total_return_net_loss,
    i.total_inventory_on_hand
FROM
    sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.year = r.year
        AND s.month_seq = r.month_seq
        AND s.promo_name = r.promo_name
    FULL OUTER JOIN inventory_agg i
        ON COALESCE(s.year, r.year) = i.year
        AND COALESCE(s.month_seq, r.month_seq) = i.month_seq
ORDER BY
    year,
    month_seq,
    promo_name
