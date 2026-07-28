WITH sales_enriched AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        d.d_date,
        d.d_year,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        p.p_promo_name,
        p.p_channel_radio,
        cr.cr_return_quantity,
        i.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        CASE WHEN cr.cr_return_quantity > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND (p.p_channel_radio = 'N' OR p.p_channel_radio IS NULL)
      AND i.inv_quantity_on_hand > 0
      AND cs.cs_net_paid_inc_ship > 500
)
SELECT
    profit_rank,
    d_date,
    w_warehouse_name,
    cs_order_number,
    cs_net_paid_inc_ship,
    cs_net_profit,
    return_flag,
    inv_quantity_on_hand,
    p_promo_name
FROM sales_enriched
WHERE profit_rank <= 10
ORDER BY profit_rank, d_date
