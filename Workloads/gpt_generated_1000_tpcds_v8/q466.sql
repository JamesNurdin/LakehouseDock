WITH cat_page_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cp.cp_description,
        cp.cp_type,
        regexp_extract(cp.cp_description, '^([A-Za-z]+)', 1) AS desc_first_word,
        CASE WHEN regexp_like(cp.cp_description, '\\d{4}') THEN 1 ELSE 0 END AS has_year_flag
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type LIKE 'C%'
),
store_sales_enh AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        s.s_store_name,
        substring(s.s_store_name, 1, 5) AS store_name_prefix,
        CASE WHEN regexp_like(s.s_store_name, '^[A-Z]{2}') THEN 1 ELSE 0 END AS store_name_twocaps_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_store_name LIKE '%Store%'
),
store_return_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        r.r_reason_desc,
        CASE WHEN regexp_like(r.r_reason_desc, 'return') THEN 1 ELSE 0 END AS reason_return_flag
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),
union_sales AS (
    SELECT
        cs_order_number AS order_key,
        cs_ext_sales_price AS sales_amount,
        desc_first_word,
        has_year_flag
    FROM cat_page_sales
    UNION
    SELECT
        ss_ticket_number AS order_key,
        ss_ext_sales_price AS sales_amount,
        store_name_prefix AS desc_first_word,
        store_name_twocaps_flag AS has_year_flag
    FROM store_sales_enh
),
intersect_keys AS (
    SELECT cs.cs_order_number AS order_key FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_order_number AS order_key FROM web_sales ws
),
full_joined AS (
    SELECT
        u.order_key,
        u.sales_amount,
        u.desc_first_word,
        u.has_year_flag,
        r.sr_return_amt,
        r.r_reason_desc,
        ROW_NUMBER() OVER (PARTITION BY u.order_key ORDER BY u.sales_amount DESC) AS rn
    FROM union_sales u
    FULL OUTER JOIN store_return_agg r ON u.order_key = r.sr_ticket_number
)
SELECT
    fj.order_key,
    SUM(fj.sales_amount) AS total_sales,
    MAX(fj.rn) AS max_row_number,
    COUNT(*) FILTER (WHERE fj.r_reason_desc IS NOT NULL) AS return_rows,
    CONCAT('Desc_', fj.desc_first_word) AS description_label
FROM full_joined fj
WHERE fj.order_key IN (SELECT order_key FROM intersect_keys)
GROUP BY fj.order_key, fj.desc_first_word, fj.has_year_flag, fj.r_reason_desc
HAVING SUM(fj.sales_amount) > 500
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
