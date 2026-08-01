WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        i.i_item_id,
        i.i_item_desc,
        i.i_category,
        i.i_product_name,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        CONCAT(s.s_store_name, ' - ', i.i_product_name) AS store_item,
        SUBSTR(i.i_item_desc, 1, 15) AS short_desc,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND REGEXP_LIKE(i.i_item_desc, '\\b[0-9]{3}\\b')
      AND s.s_store_name LIKE '%Store%'
      AND ss.ss_promo_sk IN (
          SELECT p2.p_promo_sk
          FROM tpcds.promotion p2
          WHERE REGEXP_LIKE(p2.p_promo_name, '.*Clearance.*')
      )
)
SELECT
    fs.d_year,
    fs.s_store_id,
    fs.i_category,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    SUM(fs.ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT fs.i_item_id) AS distinct_items_sold,
    CASE
        WHEN SUM(fs.ss_net_profit) > 0 THEN 'Positive'
        ELSE 'Non-Positive'
    END AS profit_status
FROM filtered_sales fs
GROUP BY CUBE (fs.d_year, fs.s_store_id, fs.i_category)
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
