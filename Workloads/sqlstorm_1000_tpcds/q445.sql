WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_call_center_sk AS call_center_sk,
           NULL AS store_sk,
           NULL AS web_site_sk,
           'Catalog' AS channel,
           cs.cs_order_number AS order_number
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           NULL,
           ss.ss_store_sk,
           NULL,
           'Store',
           ss.ss_ticket_number
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           NULL,
           NULL,
           ws.ws_web_site_sk,
           'Web',
           ws.ws_order_number
    FROM web_sales ws
),
aggregated_raw AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        sales.channel,
        i.i_category,
        i.i_class,
        i.i_brand,
        SUM(sales.net_paid) AS total_net_paid,
        SUM(sales.net_profit) AS total_net_profit,
        SUM(sales.quantity) AS total_quantity,
        COALESCE(SUM(p.p_cost * sales.quantity), 0) AS promo_cost,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promo_count,
        CONCAT(i.i_item_id, '-', i.i_product_name) AS item_key_name,
        CASE
            WHEN sales.call_center_sk IS NOT NULL THEN cc.cc_name
            WHEN sales.store_sk IS NOT NULL THEN s.s_store_name
            WHEN sales.web_site_sk IS NOT NULL THEN ws.web_name
            ELSE 'Unknown'
        END AS location_name,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand,
        sales.call_center_sk,
        sales.store_sk,
        sales.web_site_sk,
        sales.item_sk
    FROM sales_union sales
    LEFT JOIN date_dim ON sales.date_sk = date_dim.d_date_sk
    LEFT JOIN item i ON sales.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON sales.item_sk = p.p_item_sk
        AND sales.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN call_center cc ON sales.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s ON sales.store_sk = s.s_store_sk
    LEFT JOIN web_site ws ON sales.web_site_sk = ws.web_site_sk
    LEFT JOIN inventory inv ON sales.item_sk = inv.inv_item_sk
        AND sales.date_sk = inv.inv_date_sk
    WHERE date_dim.d_year BETWEEN 1999 AND 2002
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY
        date_dim.d_year,
        date_dim.d_month_seq,
        sales.channel,
        i.i_category,
        i.i_class,
        i.i_brand,
        CONCAT(i.i_item_id, '-', i.i_product_name),
        CASE
            WHEN sales.call_center_sk IS NOT NULL THEN cc.cc_name
            WHEN sales.store_sk IS NOT NULL THEN s.s_store_name
            WHEN sales.web_site_sk IS NOT NULL THEN ws.web_name
            ELSE 'Unknown'
        END,
        COALESCE(inv.inv_quantity_on_hand, 0),
        sales.call_center_sk,
        sales.store_sk,
        sales.web_site_sk,
        sales.item_sk
    HAVING SUM(sales.net_profit) > 0
),
aggregated_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank,
        (SELECT AVG(ss_sub.ss_net_profit)
         FROM store_sales ss_sub
         WHERE ss_sub.ss_item_sk = aggregated_raw.item_sk) AS avg_store_profit_for_item
    FROM aggregated_raw
)
SELECT
    d_year,
    d_month_seq,
    channel,
    i_category,
    i_class,
    i_brand,
    total_net_paid,
    total_net_profit,
    total_quantity,
    promo_cost,
    active_promo_count,
    profit_rank,
    avg_store_profit_for_item,
    item_key_name,
    location_name,
    inventory_on_hand
FROM aggregated_ranked
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, channel, profit_rank
