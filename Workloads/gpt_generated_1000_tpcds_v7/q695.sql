WITH sales_filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_net_profit,
        i.i_item_desc,
        s.s_store_name,
        d.d_year,
        d.d_month_seq
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(i.i_item_desc, '(?i)Premium|Deluxe')
      AND s.s_store_name LIKE 'A%'
)
SELECT
    CONCAT(sfs.s_store_name, ' ', CAST(sfs.d_year AS VARCHAR), '-', CAST(sfs.d_month_seq AS VARCHAR)) AS store_month,
    SUM(sfs.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt,
    SUM(CASE WHEN r.r_reason_desc IS NOT NULL AND regexp_like(r.r_reason_desc, '(?i)damage') THEN 1 ELSE 0 END) AS damage_return_cnt
FROM sales_filtered sfs
LEFT JOIN store_returns sr
    ON sfs.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY CONCAT(sfs.s_store_name, ' ', CAST(sfs.d_year AS VARCHAR), '-', CAST(sfs.d_month_seq AS VARCHAR))
ORDER BY total_net_profit DESC
LIMIT 10
