WITH cr_join AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_reversed_charge,
        cr.cr_net_loss,
        cc.cc_call_center_id,
        cc.cc_tax_percentage,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_tax_percentage > 0.05
      AND cr.cr_return_amount > 10
      AND cr.cr_return_amt_inc_tax < 5000
),
sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        i.i_category,
        i.i_brand,
        cr_join.cc_call_center_id,
        cr_join.r_reason_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN cr_join ON ss.ss_item_sk = cr_join.cr_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451900
      AND i.i_current_price BETWEEN 5 AND 1000
      AND i.i_brand IS NOT NULL
    GROUP BY GROUPING SETS (
        (ss.ss_sold_date_sk, i.i_category, i.i_brand, cr_join.cc_call_center_id, cr_join.r_reason_desc),
        (ss.ss_sold_date_sk, i.i_category, cr_join.cc_call_center_id, cr_join.r_reason_desc),
        (ss.ss_sold_date_sk, i.i_category),
        (ss.ss_sold_date_sk)
    )
)
SELECT
    ss_sold_date_sk,
    i_category,
    i_brand,
    total_sales,
    total_profit,
    distinct_tickets,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank_in_category,
    CASE WHEN total_profit < 0 THEN 'Loss' ELSE 'Profit' END AS profit_status,
    cc_call_center_id,
    r_reason_desc
FROM sales_agg
WHERE total_sales > 100
ORDER BY total_sales DESC
LIMIT 100
