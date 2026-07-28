WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        td.t_hour
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE regexp_like(cc.cc_name, '^.*Center.*$')
      AND cc.cc_state LIKE 'C%'
      AND cr.cr_return_amount > 0
)
SELECT
    cc_name,
    cc_state,
    concat(cc_name, ' - ', cc_state) AS center_full,
    regexp_extract(cc_name, '(\\w+) Center', 1) AS name_prefix,
    t_hour,
    COUNT(*) AS return_cnt,
    SUM(cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr_net_loss) > 10000 THEN 'Very High'
        WHEN SUM(cr_net_loss) > 5000  THEN 'High'
        ELSE 'Moderate'
    END AS loss_category
FROM filtered_returns fr
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = fr.cr_refunded_customer_sk
      AND ss.ss_sold_date_sk = fr.cr_returned_date_sk
)
GROUP BY
    cc_name,
    cc_state,
    concat(cc_name, ' - ', cc_state),
    regexp_extract(cc_name, '(\\w+) Center', 1),
    t_hour
ORDER BY total_net_loss DESC
LIMIT 100
