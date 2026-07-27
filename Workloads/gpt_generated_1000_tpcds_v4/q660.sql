WITH filtered_returns AS (
    SELECT DISTINCT
        sr_ticket_number,
        sr_item_sk,
        sr_store_sk,
        sr_return_time_sk,
        sr_refunded_cash,
        sr_net_loss,
        sr_return_quantity
    FROM store_returns
    WHERE sr_refunded_cash > 50
      AND sr_return_quantity <= 5
),
sales_agg AS (
    SELECT
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_net_paid_inc_tax) AS total_sales_inc_tax,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_net_paid_inc_tax > 200
      AND ss_quantity >= 1
    GROUP BY ss_item_sk, ss_ticket_number
)
SELECT
    fr.sr_store_sk,
    td.t_hour,
    td.t_am_pm,
    SUM(sa.total_sales_inc_tax) AS sum_sales_inc_tax,
    SUM(fr.sr_refunded_cash) AS sum_refunded_cash,
    COUNT(DISTINCT fr.sr_ticket_number) AS distinct_return_tickets,
    MIN(fr.sr_net_loss) AS min_net_loss,
    MAX(fr.sr_net_loss) AS max_net_loss
FROM filtered_returns fr
JOIN sales_agg sa
    ON fr.sr_ticket_number = sa.ss_ticket_number
   AND fr.sr_item_sk = sa.ss_item_sk
JOIN time_dim td
    ON fr.sr_return_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND td.t_am_pm = 'PM'
GROUP BY fr.sr_store_sk, td.t_hour, td.t_am_pm
ORDER BY sum_sales_inc_tax DESC
LIMIT 100
