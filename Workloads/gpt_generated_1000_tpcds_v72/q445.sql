WITH store_item_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_item_id,
        i.i_item_desc,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '^.*[A-Z]{2}[0-9]{2}.*$')  -- description contains two letters followed by two digits
      AND s.s_state LIKE 'A%'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_item_id,
        i.i_item_desc,
        d.d_year
)
SELECT
    sis.s_store_id,
    sis.s_store_name,
    sis.s_city,
    CONCAT(sis.s_store_name, ' - ', sis.s_city) AS store_full_name,
    SUBSTRING(sis.s_store_name FROM 1 FOR 5) AS store_name_prefix,
    sis.i_item_id,
    REGEXP_EXTRACT(sis.i_item_desc, '([A-Z]{2}[0-9]{2})', 1) AS extracted_code,
    sis.d_year,
    sis.total_quantity,
    sis.total_profit,
    CASE
        WHEN sis.total_profit > (SELECT AVG(ss_inner.ss_net_profit) FROM store_sales ss_inner)
        THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category
FROM store_item_sales sis
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
    WHERE i2.i_item_id = sis.i_item_id
      AND cs.cs_quantity > 10
)
ORDER BY sis.total_profit DESC
LIMIT 100
