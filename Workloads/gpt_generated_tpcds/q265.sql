WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_moy AS month,
        SUM(ss.ss_net_profit) AS total_sales_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_moy AS month,
        SUM(sr.sr_net_loss) AS total_returns_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
                         AND ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, d.d_year, d.d_moy
),
inventory_monthly AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        SUM(i.inv_quantity_on_hand) AS total_inventory_quantity
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sa.d_year,
    sa.month,
    sa.total_sales_net_profit,
    COALESCE(ra.total_returns_net_loss, 0) AS total_returns_net_loss,
    sa.total_discount_amount,
    sa.total_promo_cost,
    im.total_inventory_quantity,
    CASE
        WHEN COALESCE(ra.total_returns_net_loss, 0) = 0 THEN NULL
        ELSE sa.total_sales_net_profit / ra.total_returns_net_loss
    END AS profit_to_loss_ratio
FROM sales_agg sa
JOIN store s ON sa.store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON sa.store_sk = ra.store_sk
   AND sa.d_year = ra.d_year
   AND sa.month = ra.month
LEFT JOIN inventory_monthly im
    ON sa.d_year = im.d_year
   AND sa.month = im.month
ORDER BY s.s_store_id, sa.d_year, sa.month
