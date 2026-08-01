WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        CONCAT('Product: ', i.i_product_name) AS product_label,
        SUBSTRING(i.i_product_name FROM 1 FOR 5) AS product_prefix,
        regexp_extract(i.i_product_name, '^([^ ]+)') AS product_first_word,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
        (SELECT MAX(inv_quantity_on_hand) FROM inventory WHERE inv_item_sk = i.i_item_sk) AS max_inventory_qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    WHERE i.i_product_name LIKE '%Widget%'
      AND td.t_hour BETWEEN 9 AND 17
      AND regexp_like(i.i_product_name, '(?i)pro')
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    sa.i_item_sk,
    sa.i_product_name,
    sa.product_label,
    sa.product_prefix,
    sa.product_first_word,
    sa.total_sales,
    sa.total_return_amount,
    CASE WHEN sa.total_net_loss > 0 THEN 'Net Loss' ELSE 'Net Gain' END AS net_status,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_item_sk = sa.i_item_sk
          AND regexp_like(r2.r_reason_desc, '(?i)missing')
    ) THEN 'Has Missing Reason' ELSE 'No Missing Reason' END AS missing_reason_flag,
    sa.max_inventory_qty
FROM sales_agg sa
WHERE sa.total_sales > 1000
ORDER BY sa.total_sales DESC
LIMIT 100
