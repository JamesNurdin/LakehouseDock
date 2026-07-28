WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cc.cc_name,
        cc.cc_gmt_offset,
        s.s_state,
        s.s_tax_percentage,
        r.r_reason_desc,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_store_sk = sr.sr_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON r.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE s.s_state = 'CA'
      AND cc.cc_hours = '8AM-4PM'
      AND r.r_reason_id = 'AAAAAAAAFAAAAAAA'
      AND cr.cr_return_tax > 5.00
      AND ss.ss_quantity > 2
      AND ss.ss_sold_date_sk BETWEEN 2450840 AND 2450900
      AND cc.cc_gmt_offset = -5.00
      AND s.s_tax_percentage < 5.00
)
SELECT
    s_state,
    cc_name,
    r_reason_desc,
    profit_category,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    MIN(ss_net_profit) AS min_profit,
    MAX(ss_net_profit) AS max_profit
FROM base
GROUP BY
    s_state,
    cc_name,
    r_reason_desc,
    profit_category
ORDER BY total_net_paid DESC
LIMIT 100
