WITH return_data AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        i.i_item_sk,
        i.i_brand,
        i.i_item_desc,
        r.r_reason_desc,
        s.s_store_name,
        s.s_state,
        regexp_extract(i.i_item_desc, '(?i)color:([^,]*)', 1) AS extracted_color,
        regexp_extract(i.i_item_desc, '\\d{3,}', 0) AS extracted_code,
        CASE WHEN regexp_like(i.i_item_desc, '\\d{3,}') THEN true ELSE false END AS has_numeric_code
    FROM store_returns sr
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_store_name LIKE '%Market%'
      AND regexp_like(i.i_item_desc, 'color')
)
SELECT
    concat(rdata.s_store_name, ' - ', rdata.s_state) AS store_label,
    rdata.i_brand,
    COALESCE(rdata.extracted_color, 'UNKNOWN') AS item_color,
    COUNT(DISTINCT rdata.i_item_sk) AS distinct_items_returned,
    SUM(rdata.sr_net_loss) AS total_return_net_loss,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT rdata.r_reason_desc) AS distinct_return_reasons
FROM return_data rdata
INNER JOIN store_sales ss
    ON rdata.sr_ticket_number = ss.ss_ticket_number
   AND rdata.i_item_sk = ss.ss_item_sk
GROUP BY
    rdata.s_store_name,
    rdata.s_state,
    rdata.i_brand,
    rdata.extracted_color
ORDER BY total_return_net_loss DESC
LIMIT 100
