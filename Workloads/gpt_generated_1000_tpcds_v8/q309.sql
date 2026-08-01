WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        ca.ca_state,
        cd.cd_education_status,
        cd.cd_marital_status,
        ss.ss_quantity,
        ss.ss_sales_price,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    WHERE i.i_category_id IN (1, 2, 3)
      AND ca.ca_state IN ('CA', 'TX')
      AND cd.cd_education_status = 'College'
      AND cd.cd_marital_status = 'M'
      AND inv.inv_quantity_on_hand > 5
      AND ss.ss_sales_price > 20
      AND ss.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
      AND (cr.cr_return_amount IS NULL OR cr.cr_return_amount > 10)
),
agg AS (
    SELECT
        i_category,
        ca_state,
        SUM(ss_sales_price) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        AVG(ss_quantity) AS avg_quantity,
        COUNT(DISTINCT ss_ticket_number) AS txn_count
    FROM joined_data
    GROUP BY i_category, ca_state
    HAVING SUM(ss_sales_price) > 1000
)
SELECT
    a.i_category,
    a.ca_state,
    a.total_sales,
    a.total_returns,
    a.avg_quantity,
    a.txn_count,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank,
    (
        SELECT COUNT(*) FROM (
            SELECT sr.sr_ticket_number FROM store_returns sr WHERE sr.sr_return_amt > 0
            EXCEPT
            SELECT cr.cr_order_number FROM catalog_returns cr WHERE cr.cr_return_amount > 0
        ) diff
    ) AS except_ticket_cnt
FROM agg a
ORDER BY a.total_sales DESC
OFFSET 10 LIMIT 100
