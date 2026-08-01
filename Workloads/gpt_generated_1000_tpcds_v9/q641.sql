WITH unified_sales AS (
    SELECT
        d_cs.d_year,
        d_cs.d_month_seq,
        i.i_category,
        'Catalog' AS sales_channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        inv.inv_quantity_on_hand AS inventory_on_hand,
        cs.cs_order_number AS order_number,
        p.p_promo_id
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo ON p.p_start_date_sk = d_promo.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_cs.d_date_sk
    WHERE d_cs.d_year = 2001
      AND i.i_category = 'Sports'
      AND cc.cc_state = 'CA'
      AND inv.inv_quantity_on_hand > 500
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
),
web_sales_unified AS (
    SELECT
        d_ws.d_year,
        d_ws.d_month_seq,
        i.i_category,
        'Web' AS sales_channel,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        inv.inv_quantity_on_hand AS inventory_on_hand,
        ws.ws_order_number AS order_number,
        p.p_promo_id
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo ON p.p_start_date_sk = d_promo.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
      AND inv.inv_quantity_on_hand > 500
),
combined_sales AS (
    SELECT * FROM unified_sales
    UNION ALL
    SELECT * FROM web_sales_unified
),
agg_sales AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        sales_channel,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit,
        SUM(inventory_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT order_number) AS distinct_orders
    FROM combined_sales
    GROUP BY ROLLUP (d_year, d_month_seq, i_category, sales_channel)
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    sales_channel,
    total_quantity,
    total_net_profit,
    total_inventory_on_hand,
    distinct_orders,
    (SELECT MAX(total_net_profit) FROM agg_sales a2 WHERE a2.i_category = agg_sales.i_category) AS max_category_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_year,
    AVG(total_net_profit) OVER (PARTITION BY i_category, sales_channel ORDER BY d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS mov_avg_3_months
FROM agg_sales
WHERE total_quantity > 0
ORDER BY d_year DESC, d_month_seq, i_category, sales_channel
LIMIT 100
