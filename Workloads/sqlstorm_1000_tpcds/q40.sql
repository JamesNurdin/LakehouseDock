WITH date_range AS (
    SELECT d_date_sk,
           d_date,
           CASE 
               WHEN d_holiday = 'Y' THEN 'Holiday'
               WHEN d_weekend = 'Y' THEN 'Weekend'
               ELSE 'Weekday'
           END AS day_type
    FROM date_dim
    WHERE d_date BETWEEN DATE '1999-12-01' AND DATE '1999-12-31'
),
sales_union AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        ss.ss_item_sk AS item_sk,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        'store' AS channel,
        ss.ss_net_paid AS net_paid,
        ss.ss_sold_date_sk AS sold_date_sk,
        CONCAT('STORE_', i.i_item_id) AS item_key
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        cs.cs_item_sk AS item_sk,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        'catalog' AS channel,
        cs.cs_net_paid AS net_paid,
        cs.cs_sold_date_sk AS sold_date_sk,
        CONCAT('CATALOG_', i.i_item_id) AS item_key
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        ws.ws_item_sk AS item_sk,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        'web' AS channel,
        ws.ws_net_paid AS net_paid,
        ws.ws_sold_date_sk AS sold_date_sk,
        CONCAT('WEB_', i.i_item_id) AS item_key
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
items_no_sales AS (
    SELECT i.i_item_sk
    FROM item i
    EXCEPT
    SELECT DISTINCT item_sk FROM sales_union
),
inventory_info AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        inv.inv_quantity_on_hand AS qty_on_hand,
        inv.inv_warehouse_sk AS warehouse_sk
    FROM inventory inv
    WHERE inv.inv_date_sk IN (SELECT d_date_sk FROM date_range)
),
sales_agg AS (
    SELECT
        su.customer_sk,
        su.customer_id,
        su.item_sk,
        su.product_name,
        su.category,
        su.brand,
        SUM(su.net_paid) AS total_net,
        SUM(CASE WHEN su.channel = 'store' THEN su.net_paid ELSE 0 END) AS store_net,
        SUM(CASE WHEN su.channel = 'catalog' THEN su.net_paid ELSE 0 END) AS catalog_net,
        SUM(CASE WHEN su.channel = 'web' THEN su.net_paid ELSE 0 END) AS web_net,
        COUNT(*) AS txn_count,
        COUNT(*) FILTER (WHERE su.net_paid > 0) AS positive_txn,
        MAX(su.sold_date_sk) AS latest_sold_date_sk
    FROM sales_union su
    GROUP BY 1,2,3,4,5,6
),
sales_with_inventory AS (
    SELECT
        sa.*,
        COALESCE(ii.qty_on_hand, 0) AS qty_on_hand,
        ii.warehouse_sk
    FROM sales_agg sa
    LEFT JOIN inventory_info ii ON sa.item_sk = ii.item_sk
),
ranked_sales AS (
    SELECT
        swi.*,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_net DESC) AS rn_by_cust,
        RANK() OVER (PARTITION BY category ORDER BY total_net DESC) AS rnk_by_category,
        NTILE(5) OVER (ORDER BY total_net) AS quintile
    FROM sales_with_inventory swi
),
sales_by_date AS (
    SELECT customer_sk, sold_date_sk, SUM(net_paid) AS daily_net_paid
    FROM (
        SELECT ss.ss_customer_sk AS customer_sk, ss.ss_sold_date_sk AS sold_date_sk, ss.ss_net_paid AS net_paid
        FROM store_sales ss
        UNION ALL
        SELECT cs.cs_bill_customer_sk, cs.cs_sold_date_sk, cs.cs_net_paid
        FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_bill_customer_sk, ws.ws_sold_date_sk, ws.ws_net_paid
        FROM web_sales ws
    ) raw
    GROUP BY 1,2
),
customer_daily_avg AS (
    SELECT
        c.c_customer_sk,
        AVG(sb.daily_net_paid) AS avg_daily_net
    FROM customer c
    LEFT JOIN sales_by_date sb ON sb.customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = sb.sold_date_sk AND d.d_year = 2000
    GROUP BY c.c_customer_sk
),
final_set AS (
    SELECT
        rs.customer_id,
        rs.product_name,
        rs.category,
        rs.brand,
        rs.total_net,
        rs.store_net,
        rs.catalog_net,
        rs.web_net,
        rs.qty_on_hand,
        rs.rn_by_cust,
        rs.rnk_by_category,
        rs.quintile,
        CASE WHEN rs.total_net = 0 THEN NULL ELSE rs.store_net / rs.total_net END AS pct_store,
        CASE WHEN rs.total_net = 0 THEN NULL ELSE rs.catalog_net / rs.total_net END AS pct_catalog,
        CASE WHEN rs.total_net = 0 THEN NULL ELSE rs.web_net / rs.total_net END AS pct_web,
        (SELECT MAX(total_net) FROM sales_agg sa2 WHERE sa2.customer_sk = rs.customer_sk) AS max_total_net_for_cust,
        ca.avg_daily_net,
        CASE WHEN ca.avg_daily_net IS NULL OR ca.avg_daily_net = 0 THEN NULL ELSE rs.total_net / ca.avg_daily_net END AS net_vs_daily_avg,
        EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = rs.item_sk AND p.p_discount_active = 'Y') AS has_active_promo,
        CASE 
            WHEN rs.total_net > 0.9 * (SELECT MAX(total_net) FROM sales_agg sa3 WHERE sa3.customer_sk = rs.customer_sk) 
            THEN CONCAT('🔥', rs.product_name)
            ELSE rs.product_name
        END AS product_label,
        COALESCE(NULLIF(rs.qty_on_hand, 0), -1) AS qty_on_hand_adj
    FROM ranked_sales rs
    LEFT JOIN customer_daily_avg ca ON ca.c_customer_sk = rs.customer_sk
    WHERE rs.rn_by_cust <= 5
      AND rs.rnk_by_category = 1
      AND rs.total_net > 0
)
SELECT *
FROM final_set
WHERE net_vs_daily_avg > 1.5
ORDER BY net_vs_daily_avg DESC
LIMIT 100
