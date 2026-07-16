WITH all_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_id,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'Catalog' AS channel,
        CAST(NULL AS integer) AS store_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'Web' AS channel,
        CAST(NULL AS integer),
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'Store' AS channel,
        ss.ss_store_sk,
        CAST(NULL AS integer),
        CAST(NULL AS integer),
        ss.ss_customer_sk
    FROM store_sales ss
),
sales_with_dims AS (
    SELECT
        a.*,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_manufact,
        COALESCE(p.p_discount_active, 'N') AS promo_active,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        s.s_state AS store_state,
        c.c_preferred_cust_flag,
        c.c_birth_year
    FROM all_sales a
    LEFT JOIN date_dim d
        ON a.sold_date_sk = d.d_date_sk
    LEFT JOIN item i
        ON a.item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON a.promo_sk = p.p_promo_sk
    LEFT JOIN store s
        ON a.store_sk = s.s_store_sk
    LEFT JOIN customer c
        ON a.customer_sk = c.c_customer_sk
),
brand_year_agg AS (
    SELECT
        d_year,
        i_brand,
        i_category,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(CASE WHEN channel = 'Catalog' THEN net_paid ELSE 0 END) AS catalog_net_paid,
        SUM(CASE WHEN channel = 'Web' THEN net_paid ELSE 0 END) AS web_net_paid,
        SUM(CASE WHEN channel = 'Store' THEN net_paid ELSE 0 END) AS store_net_paid,
        SUM(CASE WHEN channel = 'Catalog' THEN net_profit ELSE 0 END) AS catalog_net_profit,
        SUM(CASE WHEN channel = 'Web' THEN net_profit ELSE 0 END) AS web_net_profit,
        SUM(CASE WHEN channel = 'Store' THEN net_profit ELSE 0 END) AS store_net_profit,
        SUM(net_profit) / NULLIF(SUM(net_paid), 0) AS profit_margin,
        COUNT(DISTINCT order_id) AS distinct_orders,
        COUNT(DISTINCT item_sk) AS distinct_items,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        AVG(quantity) AS avg_quantity,
        SUM(CASE WHEN promo_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_count
    FROM sales_with_dims
    WHERE d_year IS NOT NULL
    GROUP BY d_year, i_brand, i_category
),
brand_year_metrics AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_year,
        LAG(total_net_profit) OVER (PARTITION BY i_brand ORDER BY d_year) AS prev_year_profit,
        (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY i_brand ORDER BY d_year)) AS yoy_profit_change,
        SUM(total_net_profit) OVER (PARTITION BY i_brand ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM brand_year_agg b
)
SELECT
    d_year,
    i_brand,
    i_category,
    total_net_paid,
    total_net_profit,
    profit_margin,
    catalog_net_paid,
    catalog_net_profit,
    web_net_paid,
    web_net_profit,
    store_net_paid,
    store_net_profit,
    distinct_orders,
    distinct_items,
    distinct_customers,
    avg_quantity,
    promo_active_count,
    profit_rank_year,
    prev_year_profit,
    yoy_profit_change,
    cumulative_profit
FROM brand_year_metrics
WHERE profit_rank_year <= 10
ORDER BY d_year, profit_rank_year
