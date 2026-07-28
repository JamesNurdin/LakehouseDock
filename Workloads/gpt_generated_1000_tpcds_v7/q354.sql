WITH filtered_sales AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_net_paid,
        i.i_item_desc,
        s.s_store_name,
        s.s_manager,
        d.d_year,
        d.d_month_seq
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND s.s_manager LIKE 'A%'
      AND d.d_year = 2002
)
SELECT 
    f.d_year,
    f.d_month_seq,
    regexp_extract(f.i_item_desc, '[0-9]{3}', 0) AS extracted_code,
    concat(f.s_store_name, ' - ', f.s_manager) AS store_info,
    sum(f.ss_net_paid) AS total_net_paid,
    count(*) AS transaction_cnt
FROM filtered_sales f
GROUP BY 
    f.d_year,
    f.d_month_seq,
    regexp_extract(f.i_item_desc, '[0-9]{3}', 0),
    concat(f.s_store_name, ' - ', f.s_manager)
ORDER BY total_net_paid DESC
LIMIT 20
