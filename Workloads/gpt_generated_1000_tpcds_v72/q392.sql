WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        i.i_item_id,
        i.i_product_name,
        i.i_class_id,
        i.i_class,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        CASE WHEN regexp_like(i.i_product_name, '[0-9]{2,}') THEN 1 ELSE 0 END AS has_number_in_name,
        regexp_extract(i.i_product_name, '([0-9]+)', 1) AS extracted_number
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE s.s_store_name LIKE '%Market%'
),
agg AS (
    SELECT
        sd.s_store_name,
        sd.s_state,
        sd.i_class,
        sd.i_class_id,
        sd.i_item_id,
        SUM(sd.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT sd.c_customer_id) AS distinct_customers,
        SUM(CASE WHEN sd.has_number_in_name = 1 THEN sd.ss_net_paid ELSE 0 END) AS net_paid_with_number,
        CONCAT(SUBSTRING(sd.i_item_id, 1, 3), '-', SUBSTRING(sd.s_state, 1, 2)) AS item_store_code
    FROM sales_data sd
    GROUP BY
        sd.s_store_name,
        sd.s_state,
        sd.i_class,
        sd.i_class_id,
        sd.i_item_id
)
SELECT
    a.s_store_name,
    a.i_class,
    a.total_net_paid,
    a.distinct_customers,
    a.net_paid_with_number,
    RANK() OVER (PARTITION BY a.i_class ORDER BY a.total_net_paid DESC) AS store_class_rank,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
        WHERE i2.i_class_id = a.i_class_id
    ) AS avg_class_net_paid,
    a.item_store_code
FROM agg a
WHERE a.item_store_code LIKE '%-%'
ORDER BY a.total_net_paid DESC
LIMIT 100
