WITH catalog_items AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_item_desc,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        w.w_state,
        cc.cc_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(i.i_item_desc, '.*[A-Z]{3}[0-9]{2}.*')
      AND cc.cc_hours LIKE '%8AM-%'
      AND substring(i.i_item_id, 1, 3) = 'ABC'
),
store_items AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_item_desc,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        c.c_email_address
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_extract(c.c_email_address, '([^@]+)@') = 'john.doe'
      AND i.i_item_desc LIKE '%Special%'
      AND concat(i.i_item_id, '-X') LIKE '%-X'
),
intersect_items AS (
    SELECT i_item_id FROM catalog_items
    INTERSECT
    SELECT i_item_id FROM store_items
)
SELECT
    i_category,
    w_state,
    cc_name,
    COUNT(DISTINCT i_item_id) AS distinct_items,
    SUM(total_sales) AS total_sales,
    SUM(total_discount) AS total_discount
FROM (
    SELECT
        i.i_category,
        w.w_state,
        cc.cc_name,
        i.i_item_id,
        cs.cs_ext_sales_price AS total_sales,
        cs.cs_ext_discount_amt AS total_discount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_item_id IN (SELECT i_item_id FROM intersect_items)
    UNION ALL
    SELECT
        i.i_category,
        NULL AS w_state,
        NULL AS cc_name,
        i.i_item_id,
        ss.ss_ext_sales_price AS total_sales,
        ss.ss_ext_discount_amt AS total_discount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_item_id IN (SELECT i_item_id FROM intersect_items)
) agg
GROUP BY CUBE (i_category, w_state, cc_name)
LIMIT 100
