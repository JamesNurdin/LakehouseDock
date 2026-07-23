WITH filtered AS (
    SELECT
        ss.ss_ext_tax,
        ss.ss_ext_list_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        sr.sr_ticket_number,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_salutation,
        r.r_reason_desc
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE c.c_salutation = 'Mrs.'
      AND ss.ss_ext_tax > 50.00
      AND r.r_reason_desc LIKE '%color%'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    r_reason_desc,
    COUNT(*) AS return_count,
    SUM(ss_net_paid) AS total_sales_net_paid,
    SUM(sr_net_loss) AS total_return_net_loss,
    SUM(ss_net_profit) - SUM(sr_net_loss) AS net_profit_adjusted,
    AVG(ss_ext_tax) AS avg_ext_tax,
    MIN(ss_ext_list_price) AS min_ext_list_price,
    MAX(ss_ext_list_price) AS max_ext_list_price
FROM filtered
GROUP BY c_customer_id, c_first_name, c_last_name, r_reason_desc
ORDER BY net_profit_adjusted DESC
LIMIT 100
