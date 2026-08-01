/* goal: Calculate total net profit per item, promotion and return reason across catalog, store and web channels, filter to profitable groups, include a profit flag, average warehouse size for the warehouse's country, and limit to the top 100 results */
WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        r.r_reason_desc,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_indicator,
        (
            SELECT AVG(w2.w_warehouse_sq_ft)
            FROM warehouse w2
            WHERE w2.w_country = w.w_country
        ) AS avg_warehouse_sq_ft_in_country,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN "store" s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE EXISTS (
        SELECT 1
        FROM "store" s2
        WHERE s2.s_state = s.s_state
          AND s2.s_tax_percentage > 0.05
    )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        r.r_reason_desc,
        w.w_country
    HAVING SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) > 0
)
SELECT
    i_item_id,
    i_product_name,
    p_promo_name,
    r_reason_desc,
    catalog_net_profit,
    store_net_profit,
    web_net_profit,
    total_net_profit,
    profit_indicator,
    avg_warehouse_sq_ft_in_country,
    orders_count
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
