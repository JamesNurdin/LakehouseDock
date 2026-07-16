WITH
unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS sales_channel
    FROM catalog_sales cs

    UNION ALL

    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_promo_sk,
        NULL,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        'store'
    FROM store_sales ss

    UNION ALL

    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_promo_sk,
        NULL,
        ws.ws_warehouse_sk,
        ws.ws_bill_customer_sk,
        'web'
    FROM web_sales ws
),
category_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_category_id,
        SUM(us.ext_sales_price) AS total_sales,
        SUM(us.net_profit) AS total_profit,
        AVG(us.discount_amt) AS avg_discount,
        COUNT(DISTINCT us.item_sk) AS distinct_items
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_category_id
),
category_rank AS (
    SELECT
        cs.*,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_sales DESC) AS category_rank
    FROM category_sales cs
),
customer_sales AS (
    SELECT
        d.d_year,
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        SUM(us.net_paid) AS total_spent,
        SUM(us.net_profit) AS total_profit,
        COUNT(DISTINCT us.item_sk) AS distinct_items
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN customer c ON us.customer_sk = c.c_customer_sk
    GROUP BY d.d_year, c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_rank AS (
    SELECT
        cs.*,
        ROW_NUMBER() OVER (PARTITION BY cs.d_year ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_sales cs
),
category_item_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_item_sk,
        SUM(us.ext_sales_price) AS item_sales
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_item_sk
),
category_item_rank AS (
    SELECT
        cis.*,
        ROW_NUMBER() OVER (PARTITION BY cis.d_year, cis.i_category ORDER BY cis.item_sales DESC) AS item_rank
    FROM category_item_sales cis
),
promo_effect AS (
    SELECT
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(*) AS usage_count,
        SUM(us.net_paid) AS promo_sales,
        SUM(us.net_profit) AS promo_profit
    FROM unified_sales us
    JOIN promotion p ON us.promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id, p.p_start_date_sk, p.p_end_date_sk
)
SELECT
    s.d_year,
    s.i_category,
    s.total_sales,
    s.total_profit,
    s.avg_discount,
    s.distinct_items,
    s.category_rank,
    (
        SELECT array_agg(row(ci.i_item_sk, ci.item_sales) ORDER BY ci.item_sales DESC)
        FROM category_item_rank ci
        WHERE ci.d_year = s.d_year
          AND ci.i_category = s.i_category
          AND ci.item_rank <= 5
    ) AS top_5_items,
    (
        SELECT array_agg(row(cr.customer_name, cr.total_spent) ORDER BY cr.total_spent DESC)
        FROM customer_rank cr
        WHERE cr.d_year = s.d_year
          AND cr.customer_rank <= 10
    ) AS top_10_customers,
    (
        SELECT array_agg(row(pe.p_promo_id, pe.promo_sales) ORDER BY pe.promo_sales DESC)
        FROM (
            SELECT p.p_promo_id, p.promo_sales
            FROM promo_effect p
            ORDER BY p.promo_sales DESC
            LIMIT 5
        ) pe
    ) AS top_5_promotions
FROM category_rank s
WHERE s.category_rank <= 5
ORDER BY s.d_year DESC, s.total_sales DESC
LIMIT 100
