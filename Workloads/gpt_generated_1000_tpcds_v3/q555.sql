WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_cs_sales,
        SUM(cs_quantity) AS total_cs_qty,
        SUM(cs_net_profit) AS total_cs_profit
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_order_number
),
promo_year_agg AS (
    SELECT
        p.p_promo_name,
        d_ss.d_year,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs_agg.total_cs_sales) AS total_catalog_sales,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
    FROM store_sales ss
    INNER JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON d_ss.d_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_ss.d_date_sk
    LEFT JOIN cs_agg ON cr.cr_item_sk = cs_agg.cs_item_sk AND cr.cr_order_number = cs_agg.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_ss.d_date_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_p_start ON p.p_start_date_sk = d_p_start.d_date_sk
    LEFT JOIN date_dim d_p_end ON p.p_end_date_sk = d_p_end.d_date_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_item_sk = ss.ss_item_sk
          AND cs_sub.cs_quantity > 5
    )
      AND d_ss.d_year BETWEEN 2000 AND 2002
    GROUP BY p.p_promo_name, d_ss.d_year
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    p_promo_name,
    d_year,
    total_store_sales,
    total_catalog_sales,
    total_catalog_returns_loss,
    total_web_returns_loss,
    total_inventory_quantity,
    store_transactions,
    SUM(total_store_sales) OVER (
        PARTITION BY p_promo_name
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_store_sales_by_promo
FROM promo_year_agg
ORDER BY total_store_sales DESC
LIMIT 100
