WITH sales_time AS (
    SELECT
        t.t_time_sk,
        t.t_hour,
        t.t_meal_time,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(ss.ss_ticket_number) AS sales_cnt,
        SUM(CASE WHEN regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{2}') THEN ss.ss_net_paid ELSE 0 END) AS net_paid_desc_pattern,
        SUM(CASE WHEN i.i_product_name LIKE '%Deluxe%' THEN ss.ss_net_paid ELSE 0 END) AS net_paid_deluxe,
        -- extract the first numeric token from the item description (if any)
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS extracted_number
    FROM
        store_sales ss
        RIGHT OUTER JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        LEFT JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
    WHERE
        t.t_meal_time IS NOT NULL
    GROUP BY
        t.t_time_sk,
        t.t_hour,
        t.t_meal_time,
        regexp_extract(i.i_item_desc, '(\\d+)', 1)
)
SELECT
    t_hour,
    t_meal_time,
    total_net_paid,
    sales_cnt,
    net_paid_desc_pattern,
    net_paid_deluxe,
    extracted_number,
    CONCAT('Hour ', CAST(t_hour AS VARCHAR), ' ', t_meal_time) AS time_label
FROM sales_time
ORDER BY total_net_paid DESC
LIMIT 20
