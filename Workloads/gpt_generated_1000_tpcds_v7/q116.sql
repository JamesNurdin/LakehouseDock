WITH sales_ret AS (
    SELECT
        cs.cs_order_number AS cs_order_number,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_ship_mode_sk AS cs_ship_mode_sk,
        cs.cs_catalog_page_sk AS cs_catalog_page_sk,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_reason_sk AS cr_reason_sk,
        r.r_reason_desc AS r_reason_desc,
        i.i_item_desc AS i_item_desc,
        cp.cp_department AS cp_department,
        sm.sm_type AS sm_type
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(i.i_item_desc, '^.*[0-9]{3}.*$')
      AND r.r_reason_desc LIKE '%color%'
)
SELECT
    concat(cp_department, '|', sm_type) AS dept_ship,
    regexp_extract(i_item_desc, '([A-Za-z]+)', 1) AS first_word,
    sum(cs_net_profit) AS total_profit,
    avg(cr_return_amount) AS avg_return_amount,
    count(distinct cs_order_number) AS order_cnt
FROM sales_ret
GROUP BY
    concat(cp_department, '|', sm_type),
    regexp_extract(i_item_desc, '([A-Za-z]+)', 1)
ORDER BY total_profit DESC
LIMIT 100
