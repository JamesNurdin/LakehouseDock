WITH sales_union AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           'store' AS sales_channel,
           ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_item_sk AS item_sk,
           ss.ss_ext_discount_amt AS ext_discount_amt
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_customer_id,
           'catalog' AS sales_channel,
           cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_discount_amt AS ext_discount_amt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_customer_id,
           'web' AS sales_channel,
           ws.ws_sold_date_sk AS sold_date_sk,
           ws.ws_quantity AS quantity,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_item_sk AS item_sk,
           ws.ws_ext_discount_amt AS ext_discount_amt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),

customer_monthly AS (
    SELECT su.c_customer_sk,
           su.c_customer_id,
           su.sales_channel,
           d.d_year,
           d.d_month_seq AS month_seq,
           SUM(su.quantity) AS total_quantity,
           SUM(su.ext_sales_price) AS total_sales,
           SUM(su.net_paid) AS total_paid,
           SUM(su.net_profit) AS total_profit,
           AVG(CASE WHEN su.ext_sales_price <> 0 THEN su.ext_discount_amt / su.ext_sales_price END) AS avg_discount_rate,
           COUNT(DISTINCT su.item_sk) AS distinct_items,
           MAX(CASE WHEN EXISTS (
               SELECT 1
               FROM promotion p
               WHERE p.p_item_sk = su.item_sk
                 AND p.p_start_date_sk <= su.sold_date_sk
                 AND p.p_end_date_sk >= su.sold_date_sk
               ) THEN 1 ELSE 0 END) AS has_promotion
    FROM sales_union su
    LEFT JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
    GROUP BY su.c_customer_sk, su.c_customer_id, su.sales_channel, d.d_year, d.d_month_seq
),

ranked_customers AS (
    SELECT cm.*,
           ROW_NUMBER() OVER (PARTITION BY cm.sales_channel ORDER BY cm.total_profit DESC) AS profit_rank,
           RANK() OVER (PARTITION BY cm.sales_channel ORDER BY cm.total_quantity DESC) AS quantity_rank,
           NTILE(5) OVER (PARTITION BY cm.sales_channel ORDER BY cm.total_sales) AS sales_quintile,
           CONCAT('CUST_', LPAD(CAST(cm.c_customer_sk AS VARCHAR), 7, '0')) AS formatted_customer_id,
           CASE
               WHEN cm.total_profit > 0 THEN 'PROFITABLE'
               WHEN cm.total_profit = 0 THEN 'BREAKEVEN'
               ELSE 'LOSS'
           END AS profit_status,
           CASE
               WHEN cm.has_promotion = 1 AND cm.avg_discount_rate > 0.2 THEN 'HIGH_DISCOUNT_PROMO'
               WHEN cm.has_promotion = 1 THEN 'PROMO'
               ELSE 'NO_PROMO'
           END AS promo_category,
           NULLIF(cm.total_profit, 0) AS profit_nonzero
    FROM customer_monthly cm
),

final_set AS (
    SELECT rc.c_customer_sk,
           rc.c_customer_id,
           rc.sales_channel,
           rc.d_year,
           rc.month_seq,
           rc.total_quantity,
           rc.total_sales,
           rc.total_paid,
           rc.total_profit,
           rc.avg_discount_rate,
           rc.distinct_items,
           rc.has_promotion,
           rc.profit_rank,
           rc.quantity_rank,
           rc.sales_quintile,
           rc.formatted_customer_id,
           rc.profit_status,
           rc.promo_category,
           rc.profit_nonzero
    FROM ranked_customers rc
    WHERE rc.profit_status = 'PROFITABLE'
       OR (rc.sales_quintile = 5 AND rc.promo_category = 'HIGH_DISCOUNT_PROMO')
),

unprofitable_set AS (
    SELECT rc.c_customer_sk,
           rc.c_customer_id,
           rc.sales_channel,
           rc.d_year,
           rc.month_seq,
           rc.total_quantity,
           rc.total_sales,
           rc.total_paid,
           rc.total_profit,
           rc.avg_discount_rate,
           rc.distinct_items,
           rc.has_promotion,
           rc.profit_rank,
           rc.quantity_rank,
           rc.sales_quintile,
           rc.formatted_customer_id,
           rc.profit_status,
           rc.promo_category,
           rc.profit_nonzero
    FROM ranked_customers rc
    WHERE rc.profit_status = 'LOSS'
)

SELECT
    c_customer_sk,
    c_customer_id,
    sales_channel,
    d_year,
    month_seq,
    total_quantity,
    total_sales,
    total_paid,
    total_profit,
    avg_discount_rate,
    distinct_items,
    has_promotion,
    profit_rank,
    quantity_rank,
    sales_quintile,
    formatted_customer_id,
    profit_status,
    promo_category,
    profit_nonzero
FROM (
    SELECT
        c_customer_sk,
        c_customer_id,
        sales_channel,
        d_year,
        month_seq,
        total_quantity,
        total_sales,
        total_paid,
        total_profit,
        avg_discount_rate,
        distinct_items,
        has_promotion,
        profit_rank,
        quantity_rank,
        sales_quintile,
        formatted_customer_id,
        profit_status,
        promo_category,
        profit_nonzero
    FROM final_set
    UNION ALL
    SELECT
        c_customer_sk,
        c_customer_id,
        sales_channel,
        d_year,
        month_seq,
        total_quantity,
        total_sales,
        total_paid,
        total_profit,
        avg_discount_rate,
        distinct_items,
        has_promotion,
        profit_rank,
        quantity_rank,
        sales_quintile,
        formatted_customer_id,
        profit_status,
        promo_category,
        profit_nonzero
    FROM unprofitable_set up
    WHERE NOT EXISTS (
        SELECT 1
        FROM final_set f
        WHERE f.c_customer_sk = up.c_customer_sk
          AND f.sales_channel = up.sales_channel
          AND f.d_year = up.d_year
          AND f.month_seq = up.month_seq
    )
) AS combined
INTERSECT
SELECT
    c_customer_sk,
    c_customer_id,
    sales_channel,
    d_year,
    month_seq,
    total_quantity,
    total_sales,
    total_paid,
    total_profit,
    avg_discount_rate,
    distinct_items,
    has_promotion,
    profit_rank,
    quantity_rank,
    sales_quintile,
    formatted_customer_id,
    profit_status,
    promo_category,
    profit_nonzero
FROM final_set
WHERE formatted_customer_id LIKE 'CUST_0%'
