WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        MAX(td_sales.t_hour) AS sales_hour
    FROM store_sales ss
    JOIN time_dim td_sales ON ss.ss_sold_time_sk = td_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_county = 'Jackson County'
      AND s.s_rec_end_date >= DATE '1999-01-01'
      AND i.i_current_price > 10
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, i.i_product_name
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS total_returns,
        r.r_reason_desc
    FROM store_returns sr
    JOIN time_dim td_returns ON sr.sr_return_time_sk = td_returns.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY sr.sr_store_sk, sr.sr_item_sk, r.r_reason_desc
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        COUNT(*) AS warehouse_count
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND w.w_state = 'CA'
    GROUP BY inv.inv_item_sk, w.w_warehouse_name
)
SELECT
    s.s_store_name,
    i.i_product_name,
    sa.total_sales_profit,
    ra.total_return_loss,
    ia.total_on_hand,
    (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) AS net_margin,
    RANK() OVER (
        PARTITION BY s.s_store_name
        ORDER BY (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) DESC
    ) AS profit_rank
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN returns_agg ra ON ra.sr_store_sk = s.s_store_sk AND ra.sr_item_sk = i.i_item_sk
LEFT JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk
ORDER BY s.s_store_name, net_margin DESC
LIMIT 100
