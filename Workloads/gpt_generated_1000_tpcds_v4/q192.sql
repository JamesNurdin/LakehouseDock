WITH sales_agg AS (
    SELECT
        ds.d_date AS sales_date,
        wp.wp_web_page_id,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_date_sk = ds.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = ds.d_date_sk
    JOIN date_dim dwpa ON wp.wp_access_date_sk = dwpa.d_date_sk
    JOIN date_dim dps ON p.p_start_date_sk = dps.d_date_sk
    JOIN date_dim dpe ON p.p_end_date_sk = dpe.d_date_sk
    WHERE ds.d_year = 2000
      AND ds.d_quarter_name = '1900Q3'
      AND p.p_channel_dmail = 'Y'
      AND p.p_discount_active = 'Y'
      AND wp.wp_autogen_flag = 'N'
      AND i.inv_quantity_on_hand > 100
      AND cs.cs_net_profit > 0
    GROUP BY ds.d_date, wp.wp_web_page_id, p.p_promo_name
)
SELECT
    sales_date,
    wp_web_page_id,
    p_promo_name,
    total_net_profit,
    total_quantity,
    avg_discount,
    total_sales_price,
    total_inventory_qty,
    RANK() OVER (PARTITION BY sales_date ORDER BY total_net_profit DESC) AS profit_rank_by_date,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank
FROM sales_agg
ORDER BY sales_date DESC, profit_rank_by_date
LIMIT 100
