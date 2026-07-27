WITH returns_by_item_wh AS (
    SELECT
        cr_item_sk,
        cr_warehouse_sk,
        cr_refunded_addr_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_tax > 0
      AND cr_return_quantity >= 1
      AND cr_returning_customer_sk > 1000000
      AND cr_refunded_customer_sk > 1000000
      AND cr_reason_sk IS NOT NULL
    GROUP BY cr_item_sk, cr_warehouse_sk, cr_refunded_addr_sk
)
SELECT
    w.w_state,
    i.i_category,
    SUM(r.total_return_amount) AS sum_return_amount,
    AVG(r.total_net_loss) AS avg_net_loss,
    COUNT(DISTINCT r.cr_item_sk) AS distinct_items
FROM returns_by_item_wh r
JOIN tpcds.item i
    ON r.cr_item_sk = i.i_item_sk
JOIN tpcds.warehouse w
    ON r.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer_address ca
    ON r.cr_refunded_addr_sk = ca.ca_address_sk
WHERE w.w_city LIKE 'A%'
  AND ca.ca_state = 'CA'
  AND i.i_current_price BETWEEN 10 AND 500
  AND i.i_brand_id IN (1, 2, 3)
  AND w.w_gmt_offset BETWEEN -5 AND 0
GROUP BY w.w_state, i.i_category
HAVING SUM(r.total_return_amount) > 1000
ORDER BY sum_return_amount DESC
LIMIT 100
