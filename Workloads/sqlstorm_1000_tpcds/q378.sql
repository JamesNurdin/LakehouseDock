WITH date_filter AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2001
),
sales_union AS (
    SELECT cs.cs_order_number AS order_id,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales,
           'catalog' AS sales_channel,
           cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    UNION ALL
    SELECT ss.ss_ticket_number AS order_id,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales,
           'store' AS sales_channel,
           NULL AS call_center_sk
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    UNION ALL
    SELECT ws.ws_order_number AS order_id,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_quantity AS quantity,
           ws.ws_ext_sales_price AS ext_sales,
           'web' AS sales_channel,
           NULL AS call_center_sk
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
),
customer_last_purchase AS (
    SELECT s.customer_sk,
           MAX(d.d_date) AS last_purchase_date
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY s.customer_sk
),
customer_stats AS (
    SELECT s.customer_sk,
           c.c_customer_id,
           CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
           s.sales_channel,
           SUM(s.ext_sales) AS total_sales,
           SUM(s.quantity) AS total_quantity,
           COUNT(DISTINCT s.order_id) AS distinct_orders,
           AVG(s.quantity) AS avg_quantity_per_order
    FROM sales_union s
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    GROUP BY s.customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, s.sales_channel
),
customer_stats_with_share AS (
    SELECT cs.*,
           ROW_NUMBER() OVER (PARTITION BY cs.sales_channel ORDER BY cs.total_sales DESC) AS rn_by_channel,
           SUM(cs.total_sales) OVER () AS total_sales_all,
           cs.total_sales / NULLIF(SUM(cs.total_sales) OVER (), 0) AS sales_share,
           AVG(cs.total_sales) OVER () AS avg_total_sales
    FROM customer_stats cs
),
top_customers AS (
    SELECT csws.customer_sk,
           csws.c_customer_id,
           csws.full_name,
           csws.sales_channel,
           csws.total_sales,
           csws.total_quantity,
           csws.distinct_orders,
           csws.avg_quantity_per_order,
           csws.sales_share,
           csws.rn_by_channel,
           clp.last_purchase_date,
           CASE WHEN csws.total_sales > csws.avg_total_sales THEN 'HIGH' ELSE 'LOW' END AS sales_category,
           COALESCE(
               (
                   SELECT p.p_promo_id
                   FROM sales_union su
                   JOIN promotion p ON su.item_sk = p.p_item_sk
                   WHERE su.customer_sk = csws.customer_sk
                   ORDER BY p.p_start_date_sk DESC
                   LIMIT 1
               ), 'NO_PROMO') AS latest_promo_id
    FROM customer_stats_with_share csws
    LEFT JOIN customer_last_purchase clp ON csws.customer_sk = clp.customer_sk
    WHERE csws.rn_by_channel <= 5
)
SELECT
    tc.customer_sk,
    tc.c_customer_id,
    tc.full_name,
    tc.sales_channel,
    format('%,.2f', tc.total_sales) AS total_sales_formatted,
    tc.total_quantity,
    tc.distinct_orders,
    round(tc.avg_quantity_per_order, 2) AS avg_qty_per_order,
    CASE WHEN tc.sales_category = 'HIGH' THEN '🔥' ELSE '' END AS sales_indicator,
    tc.last_purchase_date,
    tc.latest_promo_id,
    cc.cc_name AS call_center_name
FROM top_customers tc
LEFT JOIN LATERAL (
    SELECT c.cc_name
    FROM catalog_sales cs
    JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
    WHERE cs.cs_bill_customer_sk = tc.customer_sk
    ORDER BY cs.cs_sold_date_sk DESC
    LIMIT 1
) cc ON TRUE
ORDER BY tc.total_sales DESC
LIMIT 20
