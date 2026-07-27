WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        w.w_warehouse_id,
        w.w_country,
        w.w_warehouse_sq_ft,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        CASE WHEN SUM(ss.ss_ext_discount_amt) > 20 THEN 'High' ELSE 'Low' END AS discount_level,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        (SELECT AVG(ss2.ss_ext_sales_price)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = i.i_item_sk) AS avg_item_sales
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_purpose = 'Unknown'
      AND w.w_country = 'United States'
      AND w.w_warehouse_sq_ft > 500000
      AND ss.ss_sales_price > 30
      AND i.i_brand_id IS NOT NULL
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        w.w_warehouse_id,
        w.w_country,
        w.w_warehouse_sq_ft
)
SELECT
    w_warehouse_id,
    i_item_id,
    i_brand,
    i_category,
    total_sales,
    total_quantity,
    discount_level,
    avg_item_sales,
    distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_sales DESC) AS sales_rank
FROM item_sales
WHERE total_sales > 1000
ORDER BY w_warehouse_id, sales_rank
